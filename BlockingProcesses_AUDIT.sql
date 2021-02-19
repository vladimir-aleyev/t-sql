USE DataWarehouse
GO

EXEC sp_configure 'show advanced options', 1
RECONFIGURE
GO
EXEC sp_configure 'blocked process threshold', 30
RECONFIGURE
GO

ALTER DATABASE DataWarehouse SET TRUSTWORTHY ON


CREATE TABLE tbl_BlockedProcessesLog
	( post_time datetime,
      duration int,
      blocked_spid int,
      waitresource nvarchar(max),
      waitresource_db nvarchar(128),
      waitresource_schema nvarchar(128),
      waitresource_name nvarchar(128),
      blocked_hostname nvarchar(128),
      blocked_db nvarchar(128),
      blocked_login nvarchar(128),
      blocked_lasttranstarted nvarchar(32),
      blocked_inputbuf nvarchar(max),
      blocking_spid int,
      blocking_hostname nvarchar(128),
      blocking_db nvarchar(128),
      blocking_login nvarchar(128),
      blocking_lasttranstarted nvarchar(32),
      blocking_inputbuf nvarchar(max)
	)

GO

--CREATE FUNCTION [dbo].[wait_resource_name](@obj nvarchar(max))
--RETURNS @wait_resource TABLE (
--    wait_resource_database_name sysname,
--    wait_resource_schema_name sysname,
--    wait_resource_object_name sysname
--)
--AS
--BEGIN
--    DECLARE @dbid int
--    DECLARE @objid int

--    IF @obj IS NULL RETURN
--    IF @obj NOT LIKE 'OBJECT: %' RETURN

--    SET @obj = SUBSTRING(@obj, 9, LEN(@obj) - 9 + CHARINDEX(':', @obj, 9))

--    SET @dbid = LEFT(@obj, CHARINDEX(':', @obj, 1) - 1)
--    SET @objid = SUBSTRING(@obj, CHARINDEX(':', @obj, 1) + 1, CHARINDEX(':', @obj, CHARINDEX(':', @obj, 1) + 1) - CHARINDEX(':', @obj, 1) - 1)

--    INSERT INTO @wait_resource (wait_resource_database_name, wait_resource_schema_name, wait_resource_object_name)
--    SELECT db_name(@dbid), object_schema_name(@objid, @dbid), object_name(@objid, @dbid)

--    RETURN
--END
--GO


CREATE PROCEDURE sp_BlockedProcessQueue
WITH EXECUTE AS OWNER
AS
DECLARE @message_body xml
DECLARE @waitresource nvarchar(max)
DECLARE @waitresource_db nvarchar(128)
DECLARE @waitresource_schema nvarchar(128)
DECLARE @waitresource_name nvarchar(128)
DECLARE @obj nvarchar(max)
DECLARE @dbid int
DECLARE @objid int

WHILE ( 1 = 1 )
        BEGIN
            BEGIN TRANSACTION
      -- Receive the next available message FROM the queue
            WAITFOR ( RECEIVE TOP ( 1 ) -- just handle one message at a time
                  @message_body = CONVERT(XML, CONVERT(NVARCHAR(MAX), message_body))
                FROM dbo.BlockedProcessQueue ), TIMEOUT 1000 
				IF ( @@ROWCOUNT = 0 ) 
                BEGIN
                    ROLLBACK TRANSACTION
                    BREAK
                END
				SET @waitresource = @message_body.value(N'(//EVENT_INSTANCE/TextData/blocked-process-report/blocked-process/process/@waitresource)[1]', 'nvarchar(max)')
				IF
					@waitresource IS NOT NULL 
					AND
					@waitresource LIKE 'OBJECT: %'
					BEGIN
						SET @obj = SUBSTRING(@waitresource, 9, LEN(@waitresource) - 9 + CHARINDEX(':', @waitresource, 9))
						SET @dbid = LEFT(@obj, CHARINDEX(':', @obj, 1) - 1)
						SET @objid = SUBSTRING(@obj, CHARINDEX(':', @obj, 1) + 1, CHARINDEX(':', @obj, CHARINDEX(':', @obj, 1) + 1) - CHARINDEX(':', @obj, 1) - 1)
						SET @waitresource_db = db_name(@dbid)
						SET @waitresource_schema = object_schema_name(@objid, @dbid)
						SET @waitresource_name = object_name(@objid, @dbid)
					END		
				INSERT INTO 
					dbo.tbl_BlockedProcessesLog
				SELECT
					CONVERT(DATETIME, @message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'varchar(128)'))
                        AS post_time,
					CAST(@message_body.value(N'(//EVENT_INSTANCE/Duration)[1]', 'bigint') / 1000000 AS int)
						AS duration,
					@message_body.value(N'(//EVENT_INSTANCE/TextData/blocked-process-report/blocked-process/process/@spid)[1]', 'int')
						AS blocked_spid,
					@waitresource 
						AS waitresource,
					@waitresource_db
						AS waitresource_db,
					@waitresource_schema
						AS waitresource_schema,
					@waitresource_name
						AS waitresource_name,
					--@message_body.value(N'(//EVENT_INSTANCE/TextData/blocked-process-report/blocked-process/process/@waitresource)[1]', 'nvarchar(max)')
						--AS waitresource,
					@message_body.value(N'(//EVENT_INSTANCE/TextData/blocked-process-report/blocked-process/process/@hostname)[1]', 'nvarchar(128)')
						AS blocked_hostname,
					DB_NAME(@message_body.value(N'(//EVENT_INSTANCE/TextData/blocked-process-report/blocked-process/process/@currentdb)[1]', 'int'))
						AS blocked_db,
					@message_body.value(N'(//EVENT_INSTANCE/TextData/blocked-process-report/blocked-process/process/@loginname)[1]', 'nvarchar(128)')
						AS blocked_login,
					CONVERT(varchar(32), @message_body.value(N'(//EVENT_INSTANCE/TextData/blocked-process-report/blocked-process/process/@lasttranstarted)[1]', 'datetime'), 109)
						AS blocked_lasttranstarted,
					@message_body.value(N'(//EVENT_INSTANCE/TextData/blocked-process-report/blocked-process/process/inputbuf)[1]', 'nvarchar(max)')
						AS blocked_inputbuf,
					@message_body.value(N'(//EVENT_INSTANCE/TextData/blocked-process-report/blocking-process/process/@spid)[1]', 'int')
						AS blocking_spid,
					@message_body.value(N'(//EVENT_INSTANCE/TextData/blocked-process-report/blocking-process/process/@hostname)[1]', 'nvarchar(128)')
						AS blocking_hostname,
					DB_NAME(@message_body.value(N'(//EVENT_INSTANCE/TextData/blocked-process-report/blocking-process/process/@currentdb)[1]', 'int'))
						AS blocking_db,
					@message_body.value(N'(//EVENT_INSTANCE/TextData/blocked-process-report/blocking-process/process/@loginname)[1]', 'nvarchar(128)')
						AS blocking_login,
					CONVERT(varchar(32), @message_body.value(N'(//EVENT_INSTANCE/TextData/blocked-process-report/blocking-process/process/@lasttranstarted)[1]', 'datetime'), 109)
						AS blocking_lasttranstarted,
					@message_body.value(N'(//EVENT_INSTANCE/TextData/blocked-process-report/blocking-process/process/inputbuf)[1]', 'nvarchar(max)')
						AS blocking_inputbuf
			COMMIT TRANSACTION
		END
GO


CREATE QUEUE [BlockedProcessQueue] 
	WITH ACTIVATION
	(
    STATUS = ON,
    PROCEDURE_NAME = [sp_BlockedProcessQueue],
    MAX_QUEUE_READERS = 2,
    EXECUTE AS OWNER
	) 
GO

CREATE SERVICE BlockedProcessService
AUTHORIZATION dbo ON QUEUE BlockedProcessQueue ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification])
GO


CREATE EVENT NOTIFICATION Notifier_For_BlockedProcess ON SERVER WITH FAN_IN FOR BLOCKED_PROCESS_REPORT TO SERVICE 'BlockedProcessService', 'current database'
GO




