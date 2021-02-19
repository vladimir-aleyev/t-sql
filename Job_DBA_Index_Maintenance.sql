USE [msdb]
GO

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

DECLARE @DatabaseName NVARCHAR(50)
DECLARE @JobName NVARCHAR(250)
DECLARE @desc NVARCHAR(250)
DECLARE @SQL_command NVARCHAR(MAX)

-- ADD HERE THE DATABASE ON WHICH WE ARE WORKING
SET @DatabaseName = N'OperationsManagerDW';	--- !!! insert database name here !!!

SET @JobName = N'DBA_Index_Maintenance_' + @DatabaseName;
SET @desc = N'Реорганизация, перестроение индексов и статистик для БД ' + @DatabaseName  
SET @SQL_command = N'USE MASTER
			GO
			SET ANSI_NULLS ON
			GO
			SET QUOTED_IDENTIFIER ON
			GO

			-- ADD HERE THE DATABASE ON WHICH WE ARE WORKING
			USE ' + @DatabaseName + '
			GO

			SET NOCOUNT ON
			DECLARE
			@DB_NAME SYSNAME,
			@TAB_NAME SYSNAME,
			@IND_NAME VARCHAR(5000),
			@SCHEMA_NAME SYSNAME,
			@FRAG FLOAT,
			@PAGES INT

			SET @DB_NAME=DB_NAME()
			CREATE TABLE #TEMPFRAG
			(
			TABLE_NAME SYSNAME,
			INDEX_NAME VARCHAR(5000),
			FRAG FLOAT,
			PAGES INT,
			SCHEM_NAME SYSNAME
			)
			EXEC (''USE ''+@DB_NAME+'';
			INSERT INTO #TEMPFRAG
			SELECT OBJECT_NAME(F.OBJECT_ID) OBJ,I.NAME IND,
			F.AVG_FRAGMENTATION_IN_PERCENT,
			F.PAGE_COUNT,TABLE_SCHEMA
			FROM SYS.DM_DB_INDEX_PHYSICAL_STATS (DB_ID(),NULL,NULL,NULL,NULL) F
			JOIN SYS.INDEXES I
			ON(F.OBJECT_ID=I.OBJECT_ID)AND I.INDEX_ID=F.INDEX_ID
			JOIN INFORMATION_SCHEMA.TABLES S
			ON (S.TABLE_NAME=OBJECT_NAME(F.OBJECT_ID))
			--WHERE INDEX_ID<> 0
			AND F.DATABASE_ID=DB_ID()
			AND OBJECTPROPERTY(I.OBJECT_ID,''''ISSYSTEMTABLE'''')=0''
			)

			DECLARE CUR_FRAG CURSOR FOR
			SELECT * FROM #TEMPFRAG
			OPEN CUR_FRAG
			FETCH NEXT FROM CUR_FRAG INTO
			@TAB_NAME ,@IND_NAME , @FRAG , @PAGES ,@SCHEMA_NAME
			WHILE @@FETCH_STATUS=0

				BEGIN
				IF (@IND_NAME IS NOT NULL)
					BEGIN
					IF (@FRAG>30 AND @PAGES>1000)
						BEGIN
						 PRINT (''USE [''+@DB_NAME+''];ALTER INDEX [''+@IND_NAME+''] ON [''+@SCHEMA_NAME+''].[''+@TAB_NAME +''] REBUILD '')
						 EXEC (''USE [''+@DB_NAME+''];ALTER INDEX [''+@IND_NAME+''] ON [''+@SCHEMA_NAME+''].[''+@TAB_NAME +''] REBUILD '')
						END

					ELSE IF((@FRAG BETWEEN 15 AND 30 ) AND @PAGES>1000 )
					BEGIN
					--IF PAGE LEVEL LOCKING IS DISABLED (PLLD) THEN REBUILD 
						BEGIN TRY
						 PRINT (''USE [''+@DB_NAME+''];ALTER INDEX [''+@IND_NAME+''] ON [''+@SCHEMA_NAME+''].[''+@TAB_NAME +''] REORGANIZE '')
						 EXEC (''USE [''+@DB_NAME+''];ALTER INDEX [''+@IND_NAME+''] ON [''+@SCHEMA_NAME+''].[''+@TAB_NAME +''] REORGANIZE '')
						 PRINT (''USE [''+@DB_NAME+''];UPDATE STATISTICS [''+@SCHEMA_NAME+''].[''+@TAB_NAME+''] ([''+@IND_NAME+'']) '' )
						 EXEC (''USE [''+@DB_NAME+''];UPDATE STATISTICS [''+@SCHEMA_NAME+''].[''+@TAB_NAME+''] ([''+@IND_NAME+'']) '' )
						END TRY
						BEGIN CATCH
						IF ERROR_NUMBER()=2552
						 PRINT (''USE [''+@DB_NAME+''];ALTER INDEX [''+@IND_NAME+''] ON [''+@SCHEMA_NAME+''].[''+@TAB_NAME +''] REBUILD '')
						 EXEC (''USE [''+@DB_NAME+''];ALTER INDEX [''+@IND_NAME+''] ON [''+@SCHEMA_NAME+''].[''+@TAB_NAME +''] REBUILD '')
						END CATCH
					END
				ELSE
					BEGIN
					 PRINT (''USE [''+@DB_NAME+''];UPDATE STATISTICS [''+@SCHEMA_NAME+''].[''+@TAB_NAME+''] ([''+@IND_NAME+'']) '' )
					 EXEC (''USE [''+@DB_NAME+''];UPDATE STATISTICS [''+@SCHEMA_NAME+''].[''+@TAB_NAME+''] ([''+@IND_NAME+'']) '' )
					END
				END

			FETCH NEXT FROM CUR_FRAG INTO
			@TAB_NAME ,@IND_NAME , @FRAG , @PAGES ,@SCHEMA_NAME
			END

			DROP TABLE #TEMPFRAG
			CLOSE CUR_FRAG
			DEALLOCATE CUR_FRAG'



/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 25.11.15 12:47:50 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=@JobName, 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=@desc,
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa',																	--- !!! check owner name !!!
		@notify_email_operator_name=N'DBA_operator', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [step1]    Script Date: 25.11.15 12:47:51 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'step1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=@SQL_command, 
		@database_name=@DatabaseName,
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'everyWeek', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20140424, 
		@active_end_date=99991231, 
		@active_start_time=40000, 
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


