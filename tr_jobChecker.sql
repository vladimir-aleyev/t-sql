USE [msdb]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tr_jobChecker] 
ON sysjobs 
AFTER UPDATE, INSERT, DELETE AS 
SET NOCOUNT ON

-- # DECLARE VARIABLES # --

DECLARE @username VARCHAR(50), 
		@hostName VARCHAR(50), 
		@jobName VARCHAR(128),
		@subjectText VARCHAR(200),
		@servername VARCHAR(50),
		@profileName VARCHAR(50) = 'DBA_Profile',
		@recipients VARCHAR(500) = 'aleev.v@autodoc.ru'
DECLARE @TableHTML NVARCHAR(MAX);

DECLARE @sysjobs TABLE (
	[action] NVARCHAR(10) NOT NULL,
	--[job_id] uniqueidentifier NOT NULL,
	--[originating_server_id] int NOT NULL,
	[name] sysname NOT NULL,
	[enabled] tinyint NOT NULL,
	[description] nvarchar(512) NULL,
	[start_step_id] int NOT NULL,
	[category_id] int NOT NULL,
	[owner_sid] varbinary(85) NOT NULL,
	--[notify_level_eventlog] int NOT NULL,
	--[notify_level_email] int NOT NULL,
	--[notify_level_netsend] int NOT NULL,
	--[notify_level_page] int NOT NULL,
	--[notify_email_operator_id] int NOT NULL,
	--[notify_netsend_operator_id] int NOT NULL,
	--[notify_page_operator_id] int NOT NULL,
	--[delete_level] int NOT NULL,
	[date_created] datetime NOT NULL,
	[date_modified] datetime NOT NULL
	--[version_number] int NOT NULL
)


IF EXISTS (SELECT [job_id] FROM DELETED)
INSERT INTO @sysjobs SELECT 'DELETED', 	[name],[enabled],[description],[start_step_id],[category_id],[owner_sid],[date_created],[date_modified] FROM DELETED
 
IF EXISTS (SELECT [job_id] FROM INSERTED)
INSERT INTO @sysjobs SELECT 'INSERTED', [name],[enabled],[description],[start_step_id],[category_id],[owner_sid],[date_created],[date_modified] FROM INSERTED


SELECT @username = SYSTEM_USER
SELECT @hostName = HOST_NAME()
SELECT @servername = @@servername
SELECT TOP(1) @jobname = [Name] FROM @sysjobs;


IF EXISTS (SELECT [name] FROM @sysjobs)
BEGIN
		SET @TableHTML = 
		N'<H1>' +@@SERVERNAME+ ' JOBS CHANGES</H1>' +
		N'<table border="1">' +
		N'<tr><th>JOB NAME</th><th>ENABLED</th><th>DESCRIPTION</th><th>OWNER</th><th>USER NAME</th><th>HOST NAME</th><th>ACTION</th>'
		+
		N'</tr>' +
		CAST 
		(	( SELECT td = ISNULL(name,''),
						'',
						td = CASE enabled WHEN 1 THEN 'YES' ELSE 'NO' END,
						'',
						td = ISNULL(description,''),
						'',
						td = ISNULL((SELECT [name] FROM sys.server_principals WHERE sid = owner_sid),''), 
						'',
						td = ISNULL(@username,''),
						'',
						td = ISNULL(@hostName,''),
						'',
						td= ISNULL(action,''),
						''
				FROM @sysjobs
				FOR XML PATH('tr'), TYPE
			) AS NVARCHAR(MAX) 
		) +
		N'</table>' 

SET @subjectText = 'SQL Job on ' + @servername + ' : [' + @jobName + '] has been CHANGED'


EXEC msdb.dbo.sp_send_dbmail 
  @profile_name = @profileName,
  @recipients = @recipients,
  @body = @TableHTML,
  @subject = @subjectText, 
  @body_format = 'HTML';

END
