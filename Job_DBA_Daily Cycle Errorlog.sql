USE [msdb]
GO

/****** Object:  Job [DBA_Daily Cycle Errorlog]    Script Date: 20.11.14 13:55:32 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 20.11.14 13:55:32 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA_Daily Cycle Errorlog', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Cycles Errorlog when its size is over 20MB or its age over 15 days.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA_Operqator', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Adaptive Cycle Errorlog]    Script Date: 20.11.14 13:55:33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Adaptive Cycle Errorlog', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET NOCOUNT ON;
DECLARE @CycleMessage VARCHAR(255), @return_value int, @Output VARCHAR(32)
DECLARE @ErrorLogs TABLE (ArchiveNumber tinyint, DateCreated DATETIME, LogFileSizeBytes int)
INSERT into @ErrorLogs (ArchiveNumber, DateCreated, LogFileSizeBytes )
EXEC master.dbo.sp_enumerrorlogs

SELECT @CycleMessage = ''Current SQL Server ErrorLog was created on '' + CONVERT(VARCHAR, DateCreated , 105) + '' and is using '' +
CASE WHEN LogFileSizeBytes BETWEEN 1024 AND 1048575 THEN CAST(LogFileSizeBytes/1024 AS VARCHAR(10)) + '' KB.''
WHEN LogFileSizeBytes > 1048575 THEN CAST((LogFileSizeBytes/1024)/1024 AS VARCHAR(10)) + '' MB.''
ELSE CAST(LogFileSizeBytes AS VARCHAR(4)) + '' Bytes.''
END 
+ CASE WHEN LogFileSizeBytes > 20971520 THEN '' The ErrorLog will be cycled because of its size.'' -- over 20MB
WHEN DateCreated <= DATEADD(dd, -15,GETDATE()) THEN '' The ErrorLog will be cycled because of its age.'' -- over 15 days
ELSE '' The ErrorLog will not be cycled.'' end
FROM @ErrorLogs where ArchiveNumber = 1

PRINT @CycleMessage

IF @CycleMessage LIKE ''%will be cycled%''
BEGIN
	EXEC @return_value = sp_cycle_errorlog
	SELECT @Output = CASE WHEN @return_value = 0 THEN ''ErrorLog was sucessfully cycled.'' ELSE ''Failure cycling Errorlog.'' END
	PRINT @Output
END', 
		@database_name=N'master', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily Cycle Errorlog', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20120529, 
		@active_end_date=99991231, 
		@active_start_time=235900, 
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


