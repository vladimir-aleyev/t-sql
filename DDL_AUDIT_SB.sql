/* 
Script By: Aasim Abdullah/Amna Asif for ConnectSQL
Purpose: To create DDL Change Log using Service Broker,
     for multiple databases on a single instance
*/
--IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
--	CREATE DATABASE DataWarehouse
--GO
--USE [DataWarehouse]
--GO


USE [msdb] 
GO

/*Create a table to hold change log*/
CREATE TABLE [dbo].DDLChangeLog(
      [EventType] [varchar](250) NULL,
      [PostTime] [datetime] NULL,
      [ServerName] [varchar](250) NULL,
      [LoginName] [varchar](250) NULL,
      [UserName] [varchar](250) NULL,
      [DatabaseName] [varchar](250) NULL,
      [SchemaName] [varchar](250) NULL,
      [ObjectName] [varchar](250) NULL,
      [ObjectType] [varchar](250) NULL,
      [TSQLCommand] [varchar](max) NULL
) ON [PRIMARY]
 
GO
 
--Enable Service Broker
IF EXISTS ( SELECT  *
            FROM    sys.databases
            WHERE   name = 'msdb'
                    AND is_broker_enabled = 0 ) 
    ALTER DATABASE msdb SET ENABLE_BROKER ; 
GO


--Create a stored procedure which will hold logic, how to get data from queue and insert to DDLChangeLog table.
CREATE PROCEDURE [sp_EventNotification]
    WITH EXECUTE AS OWNER
AS 
    DECLARE @message_body XML 
 
    WHILE ( 1 = 1 )
        BEGIN
            BEGIN TRANSACTION
      -- Receive the next available message FROM the queue
            WAITFOR ( RECEIVE TOP ( 1 ) -- just handle one message at a time
                  @message_body = CONVERT(XML, CONVERT(NVARCHAR(MAX), message_body))
                FROM dbo.[EventNotificationQueue] ), TIMEOUT 1000  
                -- if the queue is empty for one second, give UPDATE and go away
      -- If we didn't get anything, bail out
            IF ( @@ROWCOUNT = 0 ) 
                BEGIN
                    ROLLBACK TRANSACTION
                    BREAK
                END 
            INSERT  INTO DDLChangeLog
                SELECT  @message_body.value('(/EVENT_INSTANCE/EventType)[1]',
                                            'varchar(128)') AS EventType,
                        CONVERT(DATETIME, @message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'varchar(128)'))
                        AS PostTime,
                        @message_body.value('(/EVENT_INSTANCE/ServerName)[1]',
                                            'varchar(128)') AS ServerName,
                        @message_body.value('(/EVENT_INSTANCE/LoginName)[1]',
                                            'varchar(128)') AS LoginName,
                        @message_body.value('(/EVENT_INSTANCE/UserName)[1]',
                                            'varchar(128)') AS UserName,
                        @message_body.value('(/EVENT_INSTANCE/DatabaseName)[1]',
                                            'varchar(128)') AS DatabaseName,
                        @message_body.value('(/EVENT_INSTANCE/SchemaName)[1]',
                                            'varchar(128)') AS SchemaName,
                        @message_body.value('(/EVENT_INSTANCE/ObjectName)[1]',
                                            'varchar(128)') AS ObjectName,
                        @message_body.value('(/EVENT_INSTANCE/ObjectType)[1]',
                                            'varchar(128)') AS ObjectType,
                        @message_body.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]',
                                            'nvarchar(max)') AS TSQLCommand
            
            COMMIT TRANSACTION
        END
GO 



--Create Queue To Catch Messages
CREATE QUEUE [EventNotificationQueue]
   WITH ACTIVATION -- Setup Activation Procedure
 ( STATUS= ON, PROCEDURE_NAME = DBO.[sp_EventNotification],-- Procedure to execute
   MAX_QUEUE_READERS = 2, -- maximum concurrent executions of the procedure
   EXECUTE AS OWNER) -- account to execute procedure under
GO


--Create Service
CREATE SERVICE [EventNotificationService] 
AUTHORIZATION dbo ON QUEUE dbo.EventNotificationQueue
    ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]) 
GO 
 
/*==========ON TARGET DATABASE===================*/
/*
-- Enable service broker on target database
IF EXISTS ( SELECT  *
            FROM    sys.databases
            WHERE   name = '<database_name>'
                    AND is_broker_enabled = 0 ) 
    ALTER DATABASE VBank3_MSCRM SET ENABLE_BROKER ; 
GO 
--

USE [<database_name>]
GO

--Create event notification

CREATE EVENT NOTIFICATION [Notifier_For_DDL_DATABASE_LEVEL_EVENTS] ON
    DATABASE FOR
    DDL_DATABASE_LEVEL_EVENTS -- uncomment to get all type of events information
 --   CREATE_TABLE,
 --   ALTER_TABLE,
 --   DROP_TABLE,
 --   CREATE_VIEW,
 --   ALTER_VIEW,
 --   DROP_VIEW,
 --   CREATE_INDEX,
	--ALTER_INDEX,
	--DROP_INDEX,
	--CREATE_FUNCTION,
	--ALTER_FUNCTION,
	--DROP_FUNCTION,
	--CREATE_PROCEDURE,
	--ALTER_PROCEDURE,
	--DROP_PROCEDURE,
	--CREATE_TRIGGER,
	--ALTER_TRIGGER,
	--DROP_TRIGGER,
	--CREATE_SCHEMA,
	--ALTER_SCHEMA,
	--DROP_SCHEMA 
    TO SERVICE 
    'EventNotificationService',	
    'E793CB18-E769-434E-BD15-7665F91751C5'		---- service_broker_guid of msdb DB
	-- SELECT name, service_broker_guid FROM SYS.DATABASES WHERE name = 'msdb'
GO 
*/

CREATE EVENT NOTIFICATION [Notifier_For_DDL_SERVER_LEVEL_EVENTS]
ON SERVER FOR
DDL_EVENTS
TO SERVICE 
    'EventNotificationService',	
    '314E747A-19D9-49A1-B51F-57B46FE4B254' ---- service_broker_guid of msdb DB
	-- SELECT name, service_broker_guid FROM SYS.DATABASES WHERE name = 'msdb'
 
----------How to get DDL Change Log information--------
USE msdb
GO
SELECT * FROM DBO.DDLChangeLog

----------How to check created events --------
SELECT * FROM sys.server_event_notifications
SELECT * FROM sys.event_notifications