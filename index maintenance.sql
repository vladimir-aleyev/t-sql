/*
1. Ths script reorganizes and rebuilds index for all database based on fragmentation level
2. It would not work on SQL Server where partition is enabled
3. You can use this script for all database and selected databases well. 
4. The script will both execute and print indexes which will be rebuild and reorganized
*/

IF OBJECT_ID('tempdb..#DatabaseName') IS NOT NULL DROP TABLE #DatabaseName
CREATE TABLE #DatabaseName-- Temp table to store Database names on which index operation needs to be performed on the server
(
id INT IDENTITY (1,1),
Databasename SYSNAME,
Database_id SMALLINT
)

INSERT INTO #DatabaseName
SELECT [name],[database_id] FROM SYS.DATABASES WHERE [name] LIKE ('1C_%')	--Select databases you would like rebuild/reorganize to be performed and name in ('logicalread')
AND state_desc='online' and is_read_only=0 and compatibility_level <> 80						--the script would not work for database with compatibility level 80

SELECT 'List of Databases On which Maintenance Activity will be performed'
SELECT Databasename FROM #DatabaseName

DECLARE 
@id int,
@dbname SYSNAME,
@db_id smallint,
@cmd1 nvarchar(max),
@cmd2 nvarchar(max)
--@DBID smallint
SET @ID=1
WHILE(1=1)
BEGIN
		SELECT
			@ID=ID,
			@Dbname=Databasename,
			@db_id=Database_id
		FROM
			#DatabaseName
		WHERE
			ID=@ID
--set @dbid=DB_ID(@dbname)
	IF @@ROWCOUNT=0
	BREAK
	
	IF OBJECT_ID('tempdb..#work_table') IS NOT NULL DROP TABLE #work_table
	CREATE TABLE #work_table
	(
		IDD int IDENTITY (1,1) NOT NULL,
		objectname sysname,
		indexname sysname,
		Schemaname sysname,
		AFIP float
	)


SET @Cmd1= N'USE ['+ @dbname + N'] ; 
	Insert into #work_table
	SELECT
                    o.name AS objectName                

                ,        i.name AS indexName 
				,s.name as Schemaname
                ,p.avg_fragmentation_in_percent


	FROM
		sys.dm_db_index_physical_stats (DB_ID (), NULL, NULL , NULL, null) AS p
	INNER JOIN
		sys.objects as o 
	ON p.object_id = o.object_id 
	INNER JOIN
		sys.schemas as s 
	ON s.schema_id = o.schema_id 
	INNER JOIN
		sys.indexes i 
	ON p.object_id = i.object_id 
	AND i.index_id = p.index_id 
	WHERE
		p.page_count > 1000 and p.avg_fragmentation_in_percent > 5
        AND
		p.index_id > 0 and s.name <> ''sys''
	;'
                
print @cmd1
                
EXEC sp_executesql @CMD1

SELECT * FROM #work_table

DECLARE
@Object_name sysname,
@index_name sysname,
@SchemaName sysname,
@Fragmentation float,
@command1 nvarchar (max),
@command2 nvarchar (max),
@IDD Int
SET @IDD=1
		WHILE (1=1)
		BEGIN
			SELECT 
				@Object_name =ObjectName,
				@index_name= Indexname,
				@SchemaName=Schemaname,
				@Fragmentation=AFIP
			FROM
				#work_table
			WHERE
				IDD=@IDD
			IF @@ROWCOUNT=0
			BREAK

			IF (@Fragmentation > 30)
			BEGIN
				SET @Command1 = N'USE ' + '['+@Dbname+']' + ' ; ALTER INDEX ' + '[' +@index_name +']' + N' ON '  + @SchemaName + '.' + '['+ @Object_name +']' 
					+ N' REBUILD  WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)'
				PRINT (@Command1)
				EXEC sp_executesql @command1
			END
			ELSE IF (@Fragmentation <= 30)
			BEGIN
				SET @Command2 = N'USE ' + '['+@Dbname+']' + '; ALTER INDEX ' + '[' +@index_name +']'+  N' ON ' + @SchemaName + '.'
					   +'['+ @Object_name+']' + N' REORGANIZE WITH ( LOB_COMPACTION = ON ) '
				PRINT @command2
				EXEC sp_executesql @command2
			END

		SET @IDD=@IDD+1
		END

SET @id=@id+1
END

IF OBJECT_ID('tempdb..#work_table') IS NOT NULL DROP TABLE #work_table;
IF OBJECT_ID('tempdb..#DatabaseName') IS NOT NULL DROP TABLE #DatabaseName;
