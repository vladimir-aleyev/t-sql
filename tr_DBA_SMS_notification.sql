USE [msdb]
GO
/****** Object:  Trigger [dbo].[tr_DBA_SMS_notification]    Script Date: 05.04.2018 16:27:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER TRIGGER [dbo].[tr_DBA_SMS_notification] ON [dbo].[sysmail_mailitems]
AFTER INSERT
AS

DECLARE @tmessages TABLE 
 (
	id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,	
	subj NVARCHAR(170),
	body NVARCHAR(380)
 )

DECLARE @message NVARCHAR(510)
DECLARE @subject NVARCHAR(170)
DECLARE @body NVARCHAR(340)


INSERT INTO @tmessages (subj, body)
SELECT
	REPLACE(
			REPLACE(
					REPLACE(
							LEFT(subject, CASE WHEN CHARINDEX(' on \\',subject) > 0 THEN CHARINDEX(' on \\',subject) ELSE 170 END),'\',' '
							),'_',' '
					),'''',' '
			) AS [SUBJECT],
	REPLACE(
			REPLACE(
					REPLACE(
							REPLACE(
									LEFT([body], 340),'\',' '
									),'_',' '
							),CHAR(9),''
					),'''',' '
			) AS [BODY]
FROM
	inserted
WHERE
  subject <> 'SQL Server Alert System: ''Number of Deadlocks'' occurred on \\WBSERV'
  AND
  subject <> 'SQL Server Alert System: ''Blocking Process'' occurred on \\WBSERV'
  AND
  subject <> 'SQL SERVER ALERT SYSTEM'
  AND
  body_format = 'TEXT'
ORDER BY
	sent_date DESC

SELECT TOP 1
	@subject = subj,
	@body = body
FROM
	@tmessages
ORDER BY
	id

SET @message = @subject + @body

EXECUTE dbo.sp_DBA_send_sms_notification @messagebody = @message, @recipients = '79099563680';





