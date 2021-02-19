
USE [msdb]

GO 
CREATE TABLE dbo.tbl_DeadLockLog
	( 
		DeadLock_ID int IDENTITY(1,1) CONSTRAINT pk_tblDeadLock_Log PRIMARY KEY,
		DeadLock_Detected datetime,
		DeadLock_Graph xml,
		NoMailReason nvarchar(2048)
	) 
GO 


-- Create a queue to receive messages. 
CREATE QUEUE DeadLockGraphQueue; 
GO

-- Create a service on the queue that references 
-- the event notifications contract. 
CREATE SERVICE DeadLockGraphService 
ON QUEUE DeadLockGraphQueue 
([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]); 
GO 
-- Now query the sys.databases for the service_broker_guid of the msdb database. 
SELECT service_broker_guid FROM sys.databases WHERE name = 'msdb';

CREATE EVENT NOTIFICATION Notifier_For_DeadLocks 
ON SERVER
WITH FAN_IN
FOR DEADLOCK_GRAPH 
TO SERVICE 'DeadLockGraphService' 
, 'E793CB18-E769-434E-BD15-7665F91751C5'; -- the GUID for [msdb] goes here
-- or
-- , 'current database'
GO



/****** Object:  StoredProcedure [dbo].[procReceiveDeadLock_Graph]  ******/
CREATE PROCEDURE [dbo].[sp_ReceiveDeadLock_Graph] 
AS 
DECLARE @conversation_handle uniqueidentifier 
DECLARE @message_body xml 
DECLARE @message_type_name nvarchar(128) 
DECLARE @deadlock_graph xml 
DECLARE @event_datetime datetime 
DECLARE @deadlock_id int
DECLARE @DBname sysname 
BEGIN TRY 
	BEGIN TRAN 
	WAITFOR
		( 
		RECEIVE TOP(1)
			@conversation_handle = conversation_handle,
			@message_body = CAST(message_body AS xml),
			@message_type_name = message_type_name 
		FROM
			dbo.DeadLockGraphQueue
		) 
		, TIMEOUT 10000 -- Line added 2010-07-24; 
		-- http://resquel.com/ssb/2010/07/24/ServiceBrokerCanMakeYourTransactionLogBig.aspx 
		-- Validate message 
		IF
			(@message_type_name = 'http://schemas.microsoft.com/SQL/Notifications/EventNotification'
			AND
			@message_body.exist('(/EVENT_INSTANCE/TextData/deadlock-list)') = 1)
		BEGIN 
		-- Extract the info from the message 
			SELECT
				@deadlock_graph = @message_body.query('(/EVENT_INSTANCE/TextData/deadlock-list)'),
				@event_datetime = @message_body.value('(/EVENT_INSTANCE/PostTime)[1]','datetime'),
				@DBname = DB_NAME(@message_body.value('(//*/process/@currentdb)[1]', 'varchar(10)'))
		-- Put the info in the table 
			INSERT
				dbo.tbl_DeadLockLog (DeadLock_Detected, DeadLock_Graph) 
			VALUES (@event_datetime, @deadlock_graph) 

		SELECT @deadlock_id = SCOPE_IDENTITY()
		-- Send deadlock alert mail. 
		-- Requires configured database mail, will log an error if not (or anything else goes wrong). 
		/*	BEGIN TRY 
				DECLARE @subj nvarchar(255), @bdy nvarchar(max), @qry nvarchar(max), @attfn nvarchar(255) 
				SELECT
					@subj =	'A deadlock occurred on ' + @@SERVERNAME + ', on the ' + QUOTENAME(COALESCE(@DBname, 'unknown')) + ' database',
					@bdy =	'A deadlock occurred at ' + CONVERT(varchar(50),@event_datetime, 120) + ' on SQL Server: ' + @@SERVERNAME + '. See attached xdl-file for deadlock details.' ,
					@qry =	'SET NOCOUNT ON; SELECT deadlock_graph FROM msdb.dbo.tbl_DeadLockLog WITH (READUNCOMMITTED) WHERE DeadLock_ID = ' + CAST(@deadlock_id AS varchar(10)) 
					-- Locking hint is to prevent this dynamic query to be blocked by the lock held by the insert. The dynamic SQL will not come from inside this transaction. 
					,
					@attfn = @@SERVERNAME + '_' + CAST(@deadlock_id AS varchar(10)) + '.xdl'
				EXEC [msdb].[dbo].[sp_send_dbmail]
					@profile_name = 'DBA_Profile',
					@recipients = 'sqldba@autodoc-local.ru',
					@subject = @subj,
					@body = @bdy,
					@query = @qry,
					@attach_query_result_as_file = 1,
					@query_attachment_filename = @attfn /* http://support.microsoft.com/kb/924345 */,
					@query_result_header = 0,
					@query_result_width = 32767,
					@query_no_truncate = 1 
			END TRY 
			BEGIN CATCH 
				UPDATE dbo.tbl_DeadLockLog 
				SET NoMailReason = ERROR_MESSAGE() 
				WHERE DeadLock_ID = @deadlock_id 
			END CATCH 
		*/
		END 
			ELSE -- Not an event notification with deadlock-list 
				END CONVERSATION @conversation_handle 
	COMMIT TRAN 
END TRY 
BEGIN CATCH 
	ROLLBACK TRAN 
END CATCH 


ALTER QUEUE dbo.DeadLockGraphQueue 
WITH
	STATUS = ON,
	ACTIVATION
	( 
		PROCEDURE_NAME = [msdb].[dbo].[sp_ReceiveDeadLock_Graph],
		STATUS = ON,
		MAX_QUEUE_READERS = 1,
		EXECUTE AS OWNER
	)
GO

