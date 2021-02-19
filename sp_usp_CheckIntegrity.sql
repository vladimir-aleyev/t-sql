USE [msdb]
GO

/****** Object:  StoredProcedure [dbo].[usp_CheckIntegrity]    Script Date: 08/27/2014 09:46:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_CheckIntegrity] @VLDBMode bit = 1, @SingleUser bit = 0, @CreateSnap bit = 1, @SnapPath NVARCHAR(1000) = NULL
AS
/* 
This checks the logical and physical integrity of all the objects in the specified database by performing the following operations: 
|-For VLDBs (larger than 1TB):
  |- On Sundays, if VLDB Mode = 0, runs DBCC CHECKALLOC.
  |- On Sundays, runs DBCC CHECKCATALOG.
  |- Everyday, if VLDB Mode = 0, runs DBCC CHECKTABLE or if VLDB Mode = 1, DBCC CHECKFILEGROUP on a subset of tables and views, divided by daily buckets.
|-For DBs smaller than 1TB:
  |- Every Sunday a DBCC CHECKDB checks the logical and physical integrity of all the objects in the specified database.

To set how VLDBs are handled, set @VLDBMode to 0 = Bucket by Table Size or 1 = Bucket by Filegroup Size
Buckets are built weekly, on Sunday.

IMPORTANT: Consider running DBCC CHECKDB routinely (at least, weekly). On large databases and for more frequent checks, consider using the PHYSICAL_ONLY parameter.
http://msdn.microsoft.com/en-us/library/ms176064.aspx
http://blogs.msdn.com/b/sqlserverstorageengine/archive/2006/10/20/consistency-checking-options-for-a-vldb.aspx

Excludes all Offline and Read-Only DBs, and works on databases over 1TB

If a database has Read-Only filegroups, any integrity check will fail if there are other open connections to the database.

Setting @CreateSnap = 1 will create a database snapshot before running the check on the snapshot, and drop it at the end (default).
Setting @CreateSnap = 0 means the integrity check might fail if there are other open connection on the database.
Note: set a custom snapshot creation path in @SnapPath or the same path as the database in scope will be used.

Ex.: @SnapPath = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Data'

If snapshots are not allowed and a database has Read-Only filegroups, any integrity check will fail if there are other openned connections to the database.
Setting @SingleUser = 1 will set the database in single user mode before running the check, and to multi user afterwards.
Setting @SingleUser = 0 means the integrity check might fail if there are other open connection on the database.
*/

SET NOCOUNT ON;

IF @VLDBMode NOT IN (0,1)
BEGIN
	RAISERROR('[ERROR: Must set a integrity check strategy for any VLDBs we encounter - 0 = Bucket by Table Size; 1 = Bucket by Filegroup Size]', 16, 1, N'VLDB')
	RETURN
END

IF @CreateSnap = 1 AND @SingleUser = 1
BEGIN
	RAISERROR('[ERROR: Must select only one method of checking databases with Read-Only FGs]', 16, 1, N'ReadOnlyFGs')
	RETURN
END

DECLARE @dbid int, @dbname sysname, @sqlcmd NVARCHAR(4000), @msg NVARCHAR(500), @params NVARCHAR(500)
DECLARE @filename sysname, @filecreateid int, @Message VARCHAR(1000)
DECLARE @Buckets tinyint, @BucketCnt tinyint, @BucketPages bigint, @TodayBucket tinyint, @dbsize bigint, @fg_id int, @HasROFG bigint, @sqlsnapcmd NVARCHAR(4000)
DECLARE @BucketId tinyint, @object_id int, @name sysname, @schema sysname, @type CHAR(2), @type_desc NVARCHAR(60), @used_page_count bigint

IF NOT EXISTS(SELECT [object_id] FROM sys.tables WHERE [name] = 'tblDbBuckets')
CREATE TABLE tblDbBuckets (BucketId int, 
	[database_id] int, 
	[object_id] int, 
	[name] sysname, 
	[schema] sysname, 
	[type] CHAR(2), 
	type_desc NVARCHAR(60), 
	used_page_count bigint, 
	isdone bit);
	
IF NOT EXISTS(SELECT [object_id] FROM sys.tables WHERE [name] = 'tblFgBuckets')
CREATE TABLE tblFgBuckets (BucketId int, 
	[database_id] int, 
	[data_space_id] int, 
	[name] sysname, 
	used_page_count bigint, 
	isdone bit);

IF NOT EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#tmpdbs'))
CREATE TABLE #tmpdbs (id int IDENTITY(1,1), [dbid] int, [dbname] sysname, rows_size_MB bigint, isdone bit)
IF NOT EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#tblBuckets'))
CREATE TABLE #tblBuckets (BucketId int, MaxAmount bigint, CurrentRunTotal bigint)
IF NOT EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#tblObj'))
CREATE TABLE #tblObj ([object_id] int, [name] sysname, [schema] sysname, [type] CHAR(2), type_desc NVARCHAR(60), used_page_count bigint, isdone bit)
IF NOT EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#tblFGs'))
CREATE TABLE #tblFGs ([data_space_id] int, [name] sysname, used_page_count bigint, isdone bit)
IF NOT EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#tblSnapFiles'))
CREATE TABLE #tblSnapFiles ([name] sysname, isdone bit)

SELECT @Message = '** Start: ' + CONVERT(VARCHAR, GETDATE())
RAISERROR(@Message, 0, 42) WITH NOWAIT;

INSERT INTO #tmpdbs ([dbid], [dbname], rows_size_MB, isdone)
SELECT sd.database_id, sd.name, SUM((size * 8) / 1024) AS rows_size_MB, 0 
FROM sys.databases sd (NOLOCK)
INNER JOIN sys.master_files smf (NOLOCK) ON sd.database_id = smf.database_id
WHERE sd.is_read_only = 0 AND sd.state = 0 AND sd.database_id <> 2 AND smf.[type] = 0
GROUP BY sd.database_id, sd.name--, data_space_id

WHILE (SELECT COUNT([dbid]) FROM #tmpdbs WHERE isdone = 0) > 0
BEGIN
	SET @dbid = (SELECT TOP 1 [dbid] FROM #tmpdbs WHERE isdone = 0)
	SET @dbname = (SELECT TOP 1 [dbname] FROM #tmpdbs WHERE isdone = 0)
	SET @dbsize = (SELECT TOP 1 [rows_size_MB] FROM #tmpdbs WHERE isdone = 0)
	
	-- If a snapshot is to be created, set the proper path
	IF @SnapPath IS NULL
	BEGIN
		SELECT TOP 1 @SnapPath = physical_name FROM sys.master_files WHERE database_id = @dbid AND [type] = 0 AND [state] = 0
		IF @SnapPath IS NOT NULL
		BEGIN
			SELECT @SnapPath = LEFT(@SnapPath, LEN(@SnapPath)-CHARINDEX('\',REVERSE(@SnapPath)))
		END
	END

	-- Find if database has Read-Only FGs
	SET @sqlcmd = N'USE [' + @dbname + ']; SELECT @HasROFGOUT = COUNT(data_space_id) FROM sys.filegroups WHERE is_read_only = 1'
	SET @params = N'@HasROFGOUT bigint OUTPUT';
	EXECUTE sp_executesql @sqlcmd, @params, @HasROFGOUT=@HasROFG OUTPUT;

	IF @dbsize < 1048576 -- smaller than 1TB
	BEGIN
		-- Is it Sunday yet? If so, start database check
		IF (SELECT 1 & POWER(2, DATEPART(weekday, GETDATE())-1)) > 0
		BEGIN
			IF @HasROFG > 0 AND @CreateSnap = 1 AND @SnapPath IS NOT NULL
			SELECT @msg = CHAR(10) + CONVERT(VARCHAR, GETDATE(), 9) + ' - Started integrity checks on ' + @dbname + '_CheckDB_Snapshot';
			
			IF (@HasROFG > 0 AND @SingleUser = 1) OR (@HasROFG = 0)
			SELECT @msg = CHAR(19) + CONVERT(VARCHAR, GETDATE(), 9) + ' - Started integrity checks on ' + @dbname;
			
			RAISERROR (@msg, 10, 1) WITH NOWAIT

			IF @HasROFG > 0 AND @CreateSnap = 1 AND @SnapPath IS NOT NULL
			SET @sqlcmd = 'DBCC CHECKDB (''' + @dbname + '_CheckDB_Snapshot'') WITH DATA_PURITY;'
			
			IF (@HasROFG > 0 AND @SingleUser = 1) OR (@HasROFG = 0)
			SET @sqlcmd = 'DBCC CHECKDB (' + CONVERT(NVARCHAR(10),@dbid) + ') WITH DATA_PURITY;'

			IF @HasROFG > 0 AND @CreateSnap = 1 AND @SnapPath IS NOT NULL
			BEGIN
				TRUNCATE TABLE #tblSnapFiles;
				
				INSERT INTO #tblSnapFiles
				SELECT name, 0 FROM sys.master_files WHERE database_id = @dbid AND [type] = 0;
				
				SET @filecreateid = 1
				SET @sqlsnapcmd = ''

				WHILE (SELECT COUNT([name]) FROM #tblSnapFiles WHERE isdone = 0) > 0
				BEGIN
					SELECT TOP 1 @filename = [name] FROM #tblSnapFiles WHERE isdone = 0
					SET @sqlsnapcmd = @sqlsnapcmd + CHAR(10) + '(NAME = [' + @filename + '], FILENAME = ''' + @SnapPath + '\' + @dbname + '_CheckDB_Snapshot_Data_' + CONVERT(VARCHAR(10), @filecreateid) + '.ss''),'
					SET @filecreateid = @filecreateid + 1

					UPDATE #tblSnapFiles
					SET isdone = 1 WHERE [name] = @filename;
				END;

				SELECT @sqlsnapcmd = LEFT(@sqlsnapcmd, LEN(@sqlsnapcmd)-1);

				SET @sqlcmd = 'USE master;
CREATE DATABASE [' + @dbname + '_CheckDB_Snapshot] ON ' + @sqlsnapcmd + CHAR(10) + 'AS SNAPSHOT OF [' + @dbname + '];' + CHAR(10) + @sqlcmd + CHAR(10) +
'USE master;
DROP DATABASE [' + @dbname + '_CheckDB_Snapshot];'
			END
			
			IF @HasROFG > 0 AND @CreateSnap = 1 AND @SnapPath IS NULL
			BEGIN
				SET @sqlcmd = NULL
				SELECT @Message = '** Skipping database ' + @dbname + ': Could not find a valid path to create DB snapshot - ' + CONVERT(VARCHAR, GETDATE())
				RAISERROR(@Message, 0, 42) WITH NOWAIT;
			END
			
			IF @HasROFG > 0 AND @SingleUser = 1
			BEGIN
				SET @sqlcmd = 'USE master;
ALTER DATABASE [' + @dbname + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;' + CHAR(10) + @sqlcmd + CHAR(10) + 
'USE master;
ALTER DATABASE [' + @dbname + '] SET MULTI_USER WITH ROLLBACK IMMEDIATE;'
			END

			IF @sqlcmd IS NOT NULL
			EXEC sp_executesql @sqlcmd;
		END
		ELSE
		BEGIN
			SELECT @Message = '** Skipping database ' + @dbname + ': Today is not Sunday - ' + CONVERT(VARCHAR, GETDATE())
			RAISERROR(@Message, 0, 42) WITH NOWAIT;
		END
	END;

	IF @dbsize >= 1048576 -- 1TB or Larger, then create buckets
	BEGIN
		-- Buckets are built on a weekly basis, so is it Sunday yet? If so, start building
		IF (SELECT 1 & POWER(2, DATEPART(weekday, GETDATE())-1)) > 0
		BEGIN
			TRUNCATE TABLE #tblObj
			TRUNCATE TABLE #tblBuckets
			TRUNCATE TABLE #tblFGs
			TRUNCATE TABLE tblFgBuckets
			TRUNCATE TABLE tblDbBuckets

			IF @VLDBMode = 0 -- Setup to bucketize by Table Size
			BEGIN
				SET @sqlcmd = 'SELECT so.[object_id], so.[name], ss.name, so.[type], so.type_desc, SUM(sps.used_page_count) AS used_page_count, 0
FROM [' + @dbname + '].sys.objects so
INNER JOIN [' + @dbname + '].sys.dm_db_partition_stats sps ON so.[object_id] = sps.[object_id]
INNER JOIN [' + @dbname + '].sys.indexes si ON so.[object_id] = si.[object_id]
INNER JOIN [' + @dbname + '].sys.schemas ss ON so.[schema_id] = ss.[schema_id] 
WHERE so.[type] IN (''S'', ''U'', ''V'')
GROUP BY so.[object_id], so.[name], ss.name, so.[type], so.type_desc
ORDER BY used_page_count DESC'

				INSERT INTO #tblObj
				EXEC sp_executesql @sqlcmd;
			END

			IF @VLDBMode = 1 -- Setup to bucketize by Filegroup Size
			BEGIN
				SET @sqlcmd = 'SELECT fg.data_space_id, fg.name AS [filegroup_name], SUM(sps.used_page_count) AS used_page_count, 0
FROM [' + @dbname + '].sys.dm_db_partition_stats sps
INNER JOIN [' + @dbname + '].sys.indexes i ON sps.object_id = i.object_id
INNER JOIN [' + @dbname + '].sys.partition_schemes ps ON ps.data_space_id = i.data_space_id 
INNER JOIN [' + @dbname + '].sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = sps.partition_number 
INNER JOIN [' + @dbname + '].sys.filegroups fg ON dds.data_space_id = fg.data_space_id
--WHERE fg.is_read_only = 0
GROUP BY fg.name, ps.name, fg.data_space_id
ORDER BY SUM(sps.used_page_count) DESC, fg.data_space_id'

				INSERT INTO #tblFGs
				EXEC sp_executesql @sqlcmd;
			END

			-- Create buckets
			SET @Buckets = 8
			SET @BucketCnt = 1
			SET @sqlcmd = N'SELECT @BucketPagesOUT = SUM(used_page_count)/7 FROM ' + CASE WHEN @VLDBMode = 0 THEN '#tblObj' WHEN @VLDBMode = 1 THEN '#tblFGs' END
			SET @params = N'@BucketPagesOUT bigint OUTPUT';
			EXECUTE sp_executesql @sqlcmd, @params, @BucketPagesOUT=@BucketPages OUTPUT;

			WHILE @BucketCnt <> @Buckets
			BEGIN
				INSERT INTO #tblBuckets VALUES (@BucketCnt, @BucketPages, 0) 
				SET @BucketCnt = @BucketCnt + 1
			END

			IF @VLDBMode = 0 -- Populate buckets by Table Size
			BEGIN
				WHILE (SELECT COUNT(*) FROM #tblObj WHERE isdone = 0) > 0
				BEGIN
					SELECT TOP 1 @object_id = [object_id], @name = [name], @schema = [schema], @type = [type], @type_desc = type_desc, @used_page_count = used_page_count
					FROM #tblObj
					WHERE isdone = 0
					ORDER BY used_page_count DESC

					SELECT TOP 1 @BucketId = BucketId FROM #tblBuckets ORDER BY CurrentRunTotal

					INSERT INTO tblDbBuckets 
					SELECT @BucketId, @dbid, @object_id, @name, @schema, @type, @type_desc, @used_page_count, 0;

					UPDATE #tblObj
					SET isdone = 1
					FROM #tblObj
					WHERE [object_id] = @object_id AND used_page_count = @used_page_count AND isdone = 0;

					UPDATE #tblBuckets
					SET CurrentRunTotal = CurrentRunTotal + @used_page_count
					WHERE BucketId = @BucketId;
				END
			END;

			IF @VLDBMode = 1 -- Populate buckets by Filegroup Size
			BEGIN
				WHILE (SELECT COUNT(*) FROM #tblFGs WHERE isdone = 0) > 0
				BEGIN
					SELECT TOP 1 @fg_id = [data_space_id], @name = [name], @used_page_count = used_page_count
					FROM #tblFGs
					WHERE isdone = 0
					ORDER BY used_page_count DESC

					SELECT TOP 1 @BucketId = BucketId FROM #tblBuckets ORDER BY CurrentRunTotal

					INSERT INTO tblFgBuckets 
					SELECT @BucketId, @dbid, @fg_id, @name, @used_page_count, 0;

					UPDATE #tblFGs
					SET isdone = 1
					FROM #tblFGs
					WHERE [data_space_id] = @fg_id AND used_page_count = @used_page_count AND isdone = 0;

					UPDATE #tblBuckets
					SET CurrentRunTotal = CurrentRunTotal + @used_page_count
					WHERE BucketId = @BucketId;
				END
			END
		END;

		-- What day is today? 1=Sunday, 2=Monday, 4=Tuesday, 8=Wednesday, 16=Thursday, 32=Friday, 64=Saturday
		SELECT @TodayBucket = CASE WHEN 1 & POWER(2, DATEPART(weekday, GETDATE())-1) = 1 THEN 1 
				WHEN 2 & POWER(2, DATEPART(weekday, GETDATE())-1) = 2 THEN 2
				WHEN 4 & POWER(2, DATEPART(weekday, GETDATE())-1) = 4 THEN 3
				WHEN 8 & POWER(2, DATEPART(weekday, GETDATE())-1) = 8 THEN 4
				WHEN 16 & POWER(2, DATEPART(weekday, GETDATE())-1) = 16 THEN 5
				WHEN 32 & POWER(2, DATEPART(weekday, GETDATE())-1) = 32 THEN 6
				WHEN 64 & POWER(2, DATEPART(weekday, GETDATE())-1) = 64 THEN 7
			END;

		-- Is it Sunday yet? If so, start working on allocation and catalog checks on todays bucket
		IF (SELECT 1 & POWER(2, DATEPART(weekday, GETDATE())-1)) > 0
		BEGIN
			IF @VLDBMode = 0
			BEGIN
				IF @HasROFG > 0 AND @CreateSnap = 1 AND @SnapPath IS NOT NULL
				SELECT @msg = CHAR(19) + CONVERT(VARCHAR, GETDATE(), 9) + ' - Started allocation checks on ' + @dbname + '_CheckDB_Snapshot]';
			
				IF (@HasROFG > 0 AND @SingleUser = 1) OR (@HasROFG = 0)
				SELECT @msg = CHAR(19) + CONVERT(VARCHAR, GETDATE(), 9) + ' - Started allocation checks on ' + @dbname;

				RAISERROR (@msg, 10, 1) WITH NOWAIT

				IF @HasROFG > 0 AND @CreateSnap = 1
				SET @sqlcmd = 'DBCC CHECKALLOC (''' + @dbname + '_CheckDB_Snapshot'');'
				
				IF (@HasROFG > 0 AND @SingleUser = 1) OR (@HasROFG = 0)
				SET @sqlcmd = 'DBCC CHECKALLOC (' + CONVERT(NVARCHAR(10),@dbid) + ');'

				IF @HasROFG > 0 AND @CreateSnap = 1 AND @SnapPath IS NOT NULL
				BEGIN
					TRUNCATE TABLE #tblSnapFiles;
				
					INSERT INTO #tblSnapFiles
					SELECT name, 0 FROM sys.master_files WHERE database_id = @dbid AND [type] = 0;
				
					SET @filecreateid = 1
					SET @sqlsnapcmd = ''

					WHILE (SELECT COUNT([name]) FROM #tblSnapFiles WHERE isdone = 0) > 0
					BEGIN
						SELECT TOP 1 @filename = [name] FROM #tblSnapFiles WHERE isdone = 0
						SET @sqlsnapcmd = @sqlsnapcmd + CHAR(10) + '(NAME = [' + @filename + '], FILENAME = ''' + @SnapPath + '\' + @dbname + '_CheckDB_Snapshot_Data_' + CONVERT(VARCHAR(10), @filecreateid) + '.ss''),'
						SET @filecreateid = @filecreateid + 1

						UPDATE #tblSnapFiles
						SET isdone = 1 WHERE [name] = @filename;
					END;

					SELECT @sqlsnapcmd = LEFT(@sqlsnapcmd, LEN(@sqlsnapcmd)-1);

					SET @sqlcmd = 'USE master;
CREATE DATABASE [' + @dbname + '_CheckDB_Snapshot] ON ' + @sqlsnapcmd + CHAR(10) + 'AS SNAPSHOT OF [' + @dbname + '];' + CHAR(10) + @sqlcmd + CHAR(10) +
'USE master;
DROP DATABASE [' + @dbname + '_CheckDB_Snapshot];'
				END
			
				IF @HasROFG > 0 AND @CreateSnap = 1 AND @SnapPath IS NULL
				BEGIN
					SET @sqlcmd = NULL
					SELECT @Message = '** Skipping database ' + @dbname + ': Could not find a valid path to create DB snapshot - ' + CONVERT(VARCHAR, GETDATE())
					RAISERROR(@Message, 0, 42) WITH NOWAIT;
				END
				
				IF @HasROFG > 0 AND @SingleUser = 1
				BEGIN
					SET @sqlcmd = 'USE master;
ALTER DATABASE [' + @dbname + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;' + CHAR(10) + @sqlcmd + CHAR(10) + 
'USE master;
ALTER DATABASE [' + @dbname + '] SET MULTI_USER WITH ROLLBACK IMMEDIATE;'
				END

				IF @sqlcmd IS NOT NULL
				EXEC sp_executesql @sqlcmd;
			END

			IF @HasROFG > 0 AND @CreateSnap = 1 AND @SnapPath IS NOT NULL
			SELECT @msg = CHAR(19) + CONVERT(VARCHAR, GETDATE(), 9) + ' - Started catalog checks on ' + @dbname + '_CheckDB_Snapshot';
			
			IF (@HasROFG > 0 AND @SingleUser = 1) OR (@HasROFG = 0)
			SELECT @msg = CHAR(19) + CONVERT(VARCHAR, GETDATE(), 9) + ' - Started catalog checks on ' + @dbname;

			RAISERROR (@msg, 10, 1) WITH NOWAIT

			IF @HasROFG > 0 AND @CreateSnap = 1
			SET @sqlcmd = 'DBCC CHECKCATALOG (''' + @dbname + '_CheckDB_Snapshot'');'
			
			IF (@HasROFG > 0 AND @SingleUser = 1) OR (@HasROFG = 0)
			SET @sqlcmd = 'DBCC CHECKCATALOG (' + CONVERT(NVARCHAR(10),@dbid) + ');'

			IF @HasROFG > 0 AND @CreateSnap = 1 AND @SnapPath IS NOT NULL
			BEGIN
				TRUNCATE TABLE #tblSnapFiles;
				
				INSERT INTO #tblSnapFiles
				SELECT name, 0 FROM sys.master_files WHERE database_id = @dbid AND [type] = 0;
				
				SET @filecreateid = 1
				SET @sqlsnapcmd = ''

				WHILE (SELECT COUNT([name]) FROM #tblSnapFiles WHERE isdone = 0) > 0
				BEGIN
					SELECT TOP 1 @filename = [name] FROM #tblSnapFiles WHERE isdone = 0
					SET @sqlsnapcmd = @sqlsnapcmd + CHAR(10) + '(NAME = [' + @filename + '], FILENAME = ''' + @SnapPath + '\' + @dbname + '_CheckDB_Snapshot_Data_' + CONVERT(VARCHAR(10), @filecreateid) + '.ss''),'
					SET @filecreateid = @filecreateid + 1

					UPDATE #tblSnapFiles
					SET isdone = 1 WHERE [name] = @filename;
				END;

				SELECT @sqlsnapcmd = LEFT(@sqlsnapcmd, LEN(@sqlsnapcmd)-1);

				SET @sqlcmd = 'USE master;
CREATE DATABASE [' + @dbname + '_CheckDB_Snapshot] ON ' + @sqlsnapcmd + CHAR(10) + 'AS SNAPSHOT OF [' + @dbname + '];' + CHAR(10) + @sqlcmd + CHAR(10) +
'USE master;
DROP DATABASE [' + @dbname + '_CheckDB_Snapshot];'
			END
			
			IF @HasROFG > 0 AND @CreateSnap = 1 AND @SnapPath IS NULL
			BEGIN
				SET @sqlcmd = NULL
				SELECT @Message = '** Skipping database ' + @dbname + ': Could not find a valid path to create DB snapshot - ' + CONVERT(VARCHAR, GETDATE())
				RAISERROR(@Message, 0, 42) WITH NOWAIT;
			END
			
			IF @HasROFG > 0 AND @SingleUser = 1
			BEGIN
				SET @sqlcmd = 'USE master;
ALTER DATABASE [' + @dbname + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;' + CHAR(10) + @sqlcmd + CHAR(10) + 
'USE master;
ALTER DATABASE [' + @dbname + '] SET MULTI_USER WITH ROLLBACK IMMEDIATE;'
			END
			
			IF @sqlcmd IS NOT NULL
			EXEC sp_executesql @sqlcmd;
		END

		IF @VLDBMode = 0 -- Now do table checks on todays bucket
		BEGIN
			WHILE (SELECT COUNT(*) FROM tblDbBuckets WHERE [database_id] = @dbid AND isdone = 0 AND BucketId = @TodayBucket) > 0
			BEGIN
				SELECT TOP 1 @name = [name], @schema = [schema], @used_page_count = used_page_count
				FROM tblDbBuckets
				WHERE [database_id] = @dbid AND isdone = 0 AND BucketId = @TodayBucket
				ORDER BY used_page_count DESC

				SELECT @msg = CHAR(19) + CONVERT(VARCHAR, GETDATE(), 9) + ' - Started table checks on ' + @dbname + ' - table ' + @schema + '.' + @name;
				RAISERROR (@msg, 10, 1) WITH NOWAIT

				SET @sqlcmd = 'USE [' + @dbname + '];
DBCC CHECKTABLE (''' + @schema + '.' + @name + ''') WITH DATA_PURITY;'

				IF @sqlcmd IS NOT NULL
				EXEC sp_executesql @sqlcmd;

				UPDATE tblDbBuckets
				SET isdone = 1
				FROM tblDbBuckets
				WHERE [database_id] = @dbid AND [name] = @name AND [schema] = @schema AND used_page_count = @used_page_count AND isdone = 0 AND BucketId = @TodayBucket
			END
		END

		IF @VLDBMode = 1 -- Now do filegroup checks on todays bucket
		BEGIN
			WHILE (SELECT COUNT(*) FROM tblFgBuckets WHERE [database_id] = @dbid AND isdone = 0 AND BucketId = @TodayBucket) > 0
			BEGIN
				SELECT TOP 1 @fg_id = [data_space_id], @name = [name], @used_page_count = used_page_count
				FROM tblFgBuckets
				WHERE [database_id] = @dbid AND isdone = 0 AND BucketId = @TodayBucket
				ORDER BY used_page_count DESC

				SELECT @msg = CHAR(19) + CONVERT(VARCHAR, GETDATE(), 9) + ' - Started filegroup checks on [' + @dbname + '] - filegroup ' + @name;
				RAISERROR (@msg, 10, 1) WITH NOWAIT

				IF @HasROFG > 0 AND @CreateSnap = 1
				SET @sqlcmd = 'USE [' + @dbname + '_CheckDB_Snapshot];
DBCC CHECKFILEGROUP (' + CONVERT(NVARCHAR(10), @fg_id) + ');'
				
				IF (@HasROFG > 0 AND @SingleUser = 1) OR (@HasROFG = 0)
				SET @sqlcmd = 'USE [' + @dbname + '];
DBCC CHECKFILEGROUP (' + CONVERT(NVARCHAR(10), @fg_id) + ');'

				IF @HasROFG > 0 AND @CreateSnap = 1 AND @SnapPath IS NOT NULL
				BEGIN
					TRUNCATE TABLE #tblSnapFiles;
				
					INSERT INTO #tblSnapFiles
					SELECT name, 0 FROM sys.master_files WHERE database_id = @dbid AND [type] = 0;
				
					SET @filecreateid = 1
					SET @sqlsnapcmd = ''

					WHILE (SELECT COUNT([name]) FROM #tblSnapFiles WHERE isdone = 0) > 0
					BEGIN
						SELECT TOP 1 @filename = [name] FROM #tblSnapFiles WHERE isdone = 0
						SET @sqlsnapcmd = @sqlsnapcmd + CHAR(10) + '(NAME = [' + @filename + '], FILENAME = ''' + @SnapPath + '\' + @dbname + '_CheckDB_Snapshot_Data_' + CONVERT(VARCHAR(10), @filecreateid) + '.ss''),'
						SET @filecreateid = @filecreateid + 1

						UPDATE #tblSnapFiles
						SET isdone = 1 WHERE [name] = @filename;
					END;

					SELECT @sqlsnapcmd = LEFT(@sqlsnapcmd, LEN(@sqlsnapcmd)-1);

					SET @sqlcmd = 'USE master;
CREATE DATABASE [' + @dbname + '_CheckDB_Snapshot] ON ' + @sqlsnapcmd + CHAR(10) + 'AS SNAPSHOT OF [' + @dbname + '];' + CHAR(10) + @sqlcmd + CHAR(10) +
'USE master;
DROP DATABASE [' + @dbname + '_CheckDB_Snapshot];'
				END
			
				IF @HasROFG > 0 AND @CreateSnap = 1 AND @SnapPath IS NULL
				BEGIN
					SET @sqlcmd = NULL
					SELECT @Message = '** Skipping database ' + @dbname + ': Could not find a valid path to create DB snapshot - ' + CONVERT(VARCHAR, GETDATE())
					RAISERROR(@Message, 0, 42) WITH NOWAIT;
				END
				
				IF @HasROFG > 0 AND @SingleUser = 1
				BEGIN
					SET @sqlcmd = 'USE master;
ALTER DATABASE [' + @dbname + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;' + CHAR(10) + @sqlcmd + CHAR(10) + 
'USE master;
ALTER DATABASE [' + @dbname + '] SET MULTI_USER WITH ROLLBACK IMMEDIATE;'
				END

				IF @sqlcmd IS NOT NULL
				EXEC sp_executesql @sqlcmd;

				UPDATE tblFgBuckets
				SET isdone = 1
				FROM tblFgBuckets
				WHERE [database_id] = @dbid AND [data_space_id] = @fg_id AND used_page_count = @used_page_count AND isdone = 0 AND BucketId = @TodayBucket
			END
		END
	END;
 
	UPDATE #tmpdbs
	SET isdone = 1
	FROM #tmpdbs
	WHERE [dbid] = @dbid AND isdone = 0
END;

IF EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#tmpdbs'))
DROP TABLE #tmpdbs
IF EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#tblObj'))
DROP TABLE #tblObj;
IF EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#tblBuckets'))
DROP TABLE #tblBuckets;
IF EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#tblFGs'))
DROP TABLE #tblFGs;
IF EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#tblSnapFiles'))
DROP TABLE #tblSnapFiles;

SELECT @Message = '** Finished: ' + CONVERT(VARCHAR, GETDATE())
RAISERROR(@Message, 0, 42) WITH NOWAIT;

GO


