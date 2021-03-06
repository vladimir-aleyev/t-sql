USE [master]
GO
/****** Object:  StoredProcedure [dbo].[DBA_sp_ReadSQL_Log]    Script Date: 04/08/2014 17:02:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE [dbo].[DBA_sp_ReadSQL_Log]
AS
BEGIN

/*
Parameters of master.sys.xp_readerrorlog :
1.Value of error log file you want to read: 0 = current, 1 = Archive #1, 2 = Archive #2, etc... 
2.Log file type: 1 or NULL = error log, 2 = SQL Agent log 
3.Search string 1: String one you want to search for 
4.Search string 2: String two you want to search for to further refine the results 
5.Search from start time   
6.Search to end time 
7.Sort order for results: N'asc' = ascending, N'desc' = descending
*/

DROP TABLE IF EXISTS #SQLSRV_LOG;
CREATE TABLE #SQLSRV_LOG
	(
	LogDate SMALLDATETIME,
	ProcessInfo VARCHAR(20),
	LogText VARCHAR(MAX)
	)

DROP TABLE IF EXISTS #SQLAGENT_LOG;
CREATE TABLE #SQLAGENT_LOG
	(
	LogDate SMALLDATETIME,
	ProcessInfo VARCHAR(20),
	LogText VARCHAR(MAX)
	)


DECLARE @TableHTML NVARCHAR(MAX);
DECLARE @TableHTML_sqlsrvlog NVARCHAR(MAX);
DECLARE @TableHTML_agentlog NVARCHAR(MAX);
DECLARE @Subj NVARCHAR(128)	
DECLARE @LogDateFrom DATETIME 
DECLARE @LogDateTo DATETIME 


SET @Subj = @@SERVERNAME + ' SQL Server Log, SQL Agent Log';
SET @LogDateTo = GETDATE();
SET @LogDateFrom = GETDATE() - 1;
SET @TableHTML = '';
SET @TableHTML_sqlsrvlog = '';
SET @TableHTML_agentlog = '';


INSERT INTO #SQLSRV_LOG EXEC master.sys.xp_readerrorlog 0 ,1,'disabled', null, @LogDateFrom, @LogDateTo
INSERT INTO #SQLAGENT_LOG EXEC master.sys.xp_readerrorlog 0 ,2, null, null, @LogDateFrom, @LogDateTo

IF EXISTS(SELECT TOP(1) LogDate FROM #SQLSRV_LOG)
BEGIN
	SET @TableHTML_sqlsrvlog =
    N'<H1>' +@@SERVERNAME+ ' SQL Server Log</H1>' +
    N'<table border="1">' +
    N'<tr><th>Время события</th><th>Процесс</th>' +
    N'<th>Текст</th>' +
    N'</tr>' +
    CAST ( ( SELECT TOP(1000) td = CONVERT(NVARCHAR(30),LogDate,113),
					'',
                    td = ProcessInfo,
                    '',
                    td = LogText,
                    ''
              FROM #SQLSRV_LOG
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N'</table>' 
END;

IF EXISTS(SELECT TOP(1) LogDate FROM #SQLAGENT_LOG)
BEGIN
	SET @TableHTML_agentlog =
    N'<H1>' +@@SERVERNAME+ ' SQL Server Agent Error Log</H1>' +
    N'<table border="1">' +
    N'<tr><th>Время события</th><th>Процесс</th>' +
    N'<th>Текст</th>' +
    N'</tr>' +
    CAST ( ( SELECT TOP(1000) td = CONVERT(NVARCHAR(30),LogDate,113),
					'',
                    td = ProcessInfo,
                    '',
                    td = LogText,
                    ''
              FROM #SQLAGENT_LOG
              FOR XML PATH('tr'), TYPE 
    ) AS NVARCHAR(MAX) ) +
    N'</table>'
END;

SET @TableHTML = @TableHTML_sqlsrvlog + CHAR(10) + CHAR(13) + @TableHTML_agentlog;

SET @TableHTML = REPLACE(@TableHTML,'error','<font color = "ff0000">error</font>')
SET @TableHTML = REPLACE(@TableHTML,'Failed','<font color = "ff0000">Failed</font>')
SET @TableHTML = REPLACE(@TableHTML,'failed','<font color = "ff0000">failed</font>')
SET @TableHTML = REPLACE(@TableHTML,'has not been','<font color = "ff0000">has not been</font>')


IF @TableHTML <> ''
BEGIN
	SET NOCOUNT ON;
	EXEC msdb.dbo.sp_send_dbmail 
				@profile_name = 'DBA_Profile',
				@recipients = 'Aleev.V@autodoc.ru',
				@subject = @Subj,
				@body = @TableHTML,
				@body_format = 'HTML' ;
END

DROP TABLE IF EXISTS #SQLSRV_LOG;
DROP TABLE IF EXISTS #SQLAGENT_LOG;

END