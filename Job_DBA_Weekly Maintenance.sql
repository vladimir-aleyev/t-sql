USE [msdb]
GO

/****** Object:  Job [DBA_Weekly Maintenance]    Script Date: 08/27/2014 09:35:21 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 08/27/2014 09:35:21 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA_Weekly Maintenance', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=3, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Runs weekly maintenance cycle. Most steps execute on Sundays only. For integrity checks, depending on whether the database in scope is a VLDB or not, different actions are executed. See job steps for further detail.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA_MSSQL', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [DBCC CheckDB]    Script Date: 08/27/2014 09:35:21 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBCC CheckDB', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'/* 
This checks the logical and physical integrity of all the objects in the specified database by performing the following operations: 
|-For VLDBs (larger than 1TB):
  |- On Sundays, if VLDB Mode = 0, runs DBCC CHECKALLOC.
  |- On Sundays, runs DBCC CHECKCATALOG.
  |- Everyday, if VLDB Mode = 0, runs DBCC CHECKTABLE or if VLDB Mode = 1, DBCC CHECKFILEGROUP on a subset of tables and views, divided by daily buckets.
|-For DBs smaller than 1TB:
  |- Every Sunday a DBCC CHECKDB checks the logical and physical integrity of all the objects in the specified database.

To set how VLDBs are handled, set @VLDBMode to 0 = Bucket by Table Size or 1 = Bucket by Filegroup Size

IMPORTANT: Consider running DBCC CHECKDB routinely (at least, weekly). On large databases and for more frequent checks, consider using the PHYSICAL_ONLY parameter.
http://msdn.microsoft.com/en-us/library/ms176064.aspx
http://blogs.msdn.com/b/sqlserverstorageengine/archive/2006/10/20/consistency-checking-options-for-a-vldb.aspx

If a database has Read-Only filegroups, any integrity check will fail if there are other open connections to the database.

Setting @CreateSnap = 1 will create a database snapshot before running the check on the snapshot, and drop it at the end (default).
Setting @CreateSnap = 0 means the integrity check might fail if there are other open connection on the database.


If snapshots are not allowed and a database has Read-Only filegroups, any integrity check will fail if there are other openned connections to the database.
Setting @SingleUser = 1 will set the database in single user mode before running the check, and to multi user afterwards.
Setting @SingleUser = 0 means the integrity check might fail if there are other open connection on the database.
*/

EXEC msdb.dbo.usp_CheckIntegrity @VLDBMode = 1, @SingleUser = 0, @CreateSnap = 1
', 
		@database_name=N'master', 
		@flags=20
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [update usage]    Script Date: 08/27/2014 09:35:21 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'update usage', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'/*
DBCC UPDATEUSAGE corrects the rows, used pages, reserved pages, leaf pages and data page counts for each partition in a table or index.
IMPORTANT: Consider running DBCC UPDATEUSAGE routinely (for example, weekly) only if the database undergoes frequent Data Definition Language (DDL) modifications, such as CREATE, ALTER, or DROP statements.
http://msdn.microsoft.com/en-us/library/ms188414.aspx

Exludes all Offline or Read-Only DBs. Also excludes all databases over 4GB in size.
*/

SET NOCOUNT ON;
-- Is it Sunday yet?
IF (SELECT 1 & POWER(2, DATEPART(weekday, GETDATE())-1)) > 0
BEGIN
	PRINT ''** Start: '' + CONVERT(VARCHAR, GETDATE())
	DECLARE @dbname sysname, @sqlcmd NVARCHAR(500)
	IF NOT EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID(''tempdb.dbo.#tmpdbs''))
	CREATE TABLE #tmpdbs (id int IDENTITY(1,1), [dbname] sysname, isdone bit)

	INSERT INTO #tmpdbs ([dbname], isdone)
	SELECT QUOTENAME(d.name), 0 FROM sys.databases d INNER JOIN sys.master_files smf ON d.database_id = smf.database_id
	WHERE d.is_read_only = 0 AND d.state = 0 AND d.database_id <> 2 AND smf.type = 0 AND (smf.size * 8)/1024 < 4096;

	WHILE (SELECT COUNT([dbname]) FROM #tmpdbs WHERE isdone = 0) > 0
	BEGIN
		SET @dbname = (SELECT TOP 1 [dbname] FROM #tmpdbs WHERE isdone = 0)
		SET @sqlcmd = ''DBCC UPDATEUSAGE ('' + @dbname + '')''
		PRINT CHAR(10) + CONVERT(VARCHAR, GETDATE()) + '' - Started space corrections on '' + @dbname
		EXECUTE sp_executesql @sqlcmd
		PRINT CONVERT(VARCHAR, GETDATE()) + '' - Ended space corrections on '' + @dbname
			
		UPDATE #tmpdbs
		SET isdone = 1
		FROM #tmpdbs
		WHERE [dbname] = @dbname AND isdone = 0
	END;

	IF EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID(''tempdb.dbo.#tmpdbs''))
	DROP TABLE #tmpdbs;

	PRINT ''** Finished: '' + CONVERT(VARCHAR, GETDATE())
END
ELSE
BEGIN
	PRINT ''** Skipping: Today is not Sunday - '' + CONVERT(VARCHAR, GETDATE())
END;', 
		@database_name=N'master', 
		@flags=20
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [sp_createstats]    Script Date: 08/27/2014 09:35:21 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'sp_createstats', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'/*
Creates statistics only on columns that are part of an existing index, and are not the first column in any index definition. 
Creating single-column statistics increases the number of histograms, which can improve cardinality estimates, query plans, and query performance. 
The first column of a statistics object has a histogram; other columns do not have a histogram. 

http://msdn.microsoft.com/en-us/library/ms186834.aspx

Exludes all Offline and Read-Only DBs
*/

SET NOCOUNT ON;
-- Is it Sunday yet?
IF (SELECT 1 & POWER(2, DATEPART(weekday, GETDATE())-1)) > 0
BEGIN
	PRINT ''** Start: '' + CONVERT(VARCHAR, GETDATE())
	DECLARE @dbname sysname, @sqlcmd NVARCHAR(500)

	IF NOT EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID(''tempdb.dbo.#tmpdbs''))
	CREATE TABLE #tmpdbs (id int IDENTITY(1,1), [dbname] sysname, isdone bit)

	INSERT INTO #tmpdbs ([dbname], isdone)
	SELECT QUOTENAME(name), 0 FROM sys.databases WHERE is_read_only = 0 AND state = 0 AND database_id > 4 AND is_distributor = 0;

	WHILE (SELECT COUNT([dbname]) FROM #tmpdbs WHERE isdone = 0) > 0
	BEGIN
		SET @dbname = (SELECT TOP 1 [dbname] FROM #tmpdbs WHERE isdone = 0)
		SET @sqlcmd = @dbname + ''.dbo.sp_createstats @indexonly = ''''indexonly''''''
		SELECT CHAR(10) + CONVERT(VARCHAR, GETDATE()) + '' - Started indexed stats creation on '' + @dbname
		EXECUTE sp_executesql @sqlcmd
		SELECT CONVERT(VARCHAR, GETDATE()) + '' - Ended indexed stats creation on '' + @dbname

		UPDATE #tmpdbs
		SET isdone = 1
		FROM #tmpdbs
		WHERE [dbname] = @dbname AND isdone = 0
	END;

	IF EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID(''tempdb.dbo.#tmpdbs''))
	DROP TABLE #tmpdbs;
	PRINT ''** Finished: '' + CONVERT(VARCHAR, GETDATE())
END
ELSE
BEGIN
	PRINT ''** Skipping: Today is not Sunday - '' + CONVERT(VARCHAR, GETDATE())
END;', 
		@database_name=N'master', 
		@flags=20
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Cleanup Job History]    Script Date: 08/27/2014 09:35:21 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Cleanup Job History', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Cleans msdb job history older than 30 days
SET NOCOUNT ON;
-- Is it Sunday yet?
IF (SELECT 1 & POWER(2, DATEPART(weekday, GETDATE())-1)) > 0
BEGIN
	DECLARE @date DATETIME
	SET @date = GETDATE()-30
	EXEC msdb.dbo.sp_purge_jobhistory @oldest_date=@date;
END
ELSE
BEGIN
	PRINT ''** Skipping: Today is not Sunday - '' + CONVERT(VARCHAR, GETDATE())
END;', 
		@database_name=N'msdb', 
		@flags=20
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Cleanup Maintenance Plan txt reports]    Script Date: 08/27/2014 09:35:22 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Cleanup Maintenance Plan txt reports', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Cleans maintenance plans txt reports older than 30 days
SET NOCOUNT ON;
-- Is it Sunday yet?
IF (SELECT 1 & POWER(2, DATEPART(weekday, GETDATE())-1)) > 0
BEGIN
	DECLARE @path NVARCHAR(500), @date DATETIME
	DECLARE @sqlcmd NVARCHAR(1000), @params NVARCHAR(100), @sqlmajorver int

	SELECT @sqlmajorver = CONVERT(int, (@@microsoftversion / 0x1000000) & 0xff);
	SET @date = GETDATE()-30

	IF @sqlmajorver < 11
	BEGIN
		EXEC master..xp_instance_regread N''HKEY_LOCAL_MACHINE'',N''Software\Microsoft\MSSQLServer\Setup'',N''SQLPath'', @path OUTPUT
		SET @path = @path + ''\LOG''
	END
	ELSE
	BEGIN
		SET @sqlcmd = N''SELECT @pathOUT = LEFT([path], LEN([path])-1) FROM sys.dm_os_server_diagnostics_log_configurations'';
		SET @params = N''@pathOUT NVARCHAR(2048) OUTPUT'';
		EXECUTE sp_executesql @sqlcmd, @params, @pathOUT=@path OUTPUT;
	END

	-- Default location for maintenance plan txt files is the Log folder. 
	-- If you changed from the default location since you last installed SQL Server, uncomment below and set the custom desired path.
	--SET @path = ''C:\custom_location''

	EXECUTE master..xp_delete_file 1,@path,N''txt'',@date,1
END
ELSE
BEGIN
	PRINT ''** Skipping: Today is not Sunday - '' + CONVERT(VARCHAR, GETDATE())
END;', 
		@database_name=N'master', 
		@flags=20
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Weekly Maintenance - Sundays', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20071009, 
		@active_end_date=99991231, 
		@active_start_time=83000, 
		@active_end_time=235959
		
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Weekly Maintenance - Weekdays and Saturdays', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=126, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20131017, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959 
		
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


