USE [msdb]
GO


BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ola.hallengren_FULL_BACKUP_USER_DATABASES', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'dba_alert', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'STEP_01_FULL_BACKUP_USER_DATABASES', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'if DATEPART(DAY,GETDATE()) = DATEPART(DAY,DATEADD(DY,DATEDIFF(DY,''1900-01-06'',DATEADD(MM,DATEDIFF(MM,0,GETDATE()),30))/7*7,''1900-01-06''))
BEGIN
EXECUTE dbo.DatabaseBackup
@Databases = ''USER_DATABASES''
,@Directory = ''\\<server name>\backup$''
,@BackupType = ''FULL''
,@Verify = ''Y''
,@AvailabilityGroupDirectoryStructure = ''{AvailabilityGroupName}{DirectorySeparator}{BackupType}{DirectorySeparator}{Description}{DirectorySeparator}{DatabaseName}'' 
,@CheckSum = ''Y''
,@BufferCount = 10
,@MaxTransferSize = 4194304
,@Compress = ''Y''
,@LogToTable = ''Y''
,@Description = ''MONTHLY''
,@DirectoryStructure = ''{ServerName}{DirectorySeparator}{BackupType}{DirectorySeparator}{Description}{DirectorySeparator}{DatabaseName}''
,@FileName=''{InstanceName}_{DatabaseName}_{BackupType}_{Partial}_{CopyOnly}_{Year}{Month}{Day}_{Hour}{Minute}{Second}_{FileNumber}.{FileExtension}''
,@CleanupMode =''BEFORE_BACKUP''
,@CleanupTime =4440

END
ELSE
BEGIN
EXECUTE dbo.DatabaseBackup
@Databases = ''USER_DATABASES''
,@Directory = ''\\<server name>\backup$''
,@BackupType = ''FULL''
,@Verify = ''Y''
,@CheckSum = ''Y''
,@AvailabilityGroupDirectoryStructure = ''{AvailabilityGroupName}{DirectorySeparator}{BackupType}{DirectorySeparator}{DatabaseName}''
,@BufferCount = 10
,@MaxTransferSize = 4194304
,@Compress = ''Y''
,@LogToTable = ''Y''
,@DirectoryStructure = ''{ServerName}{DirectorySeparator}{BackupType}{DirectorySeparator}{DatabaseName}''
,@FileName=''{InstanceName}_{DatabaseName}_{BackupType}_{Partial}_{CopyOnly}_{Year}{Month}{Day}_{Hour}{Minute}{Second}_{FileNumber}.{FileExtension}''
,@CleanupMode =''BEFORE_BACKUP''
,@CleanupTime =750
END
', 
		@database_name=N'msdb', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'EverySunday', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=64, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20190109, 
		@active_end_date=99991231, 
		@active_start_time=3000, 
		@active_end_time=235959--, 
		--@schedule_uid=N'cc42ef6c-4230-4185-85c8-03d1033e81ea'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


