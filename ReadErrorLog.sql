



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


CREATE TABLE #SQLSRV_LOG
	(
	LogDate SMALLDATETIME,
	ProcessInfo VARCHAR(20),
	LogText VARCHAR(500)
	)
CREATE TABLE #SQLAGENT_LOG
	(
	LogDate SMALLDATETIME,
	ProcessInfo VARCHAR(20),
	LogText VARCHAR(500)
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


INSERT INTO #SQLSRV_LOG EXEC master.sys.xp_readerrorlog 0 ,1, null, null, @LogDateFrom , @LogDateTo
INSERT INTO #SQLAGENT_LOG EXEC master.sys.xp_readerrorlog 0 ,2, null, null, @LogDateFrom , @LogDateTo

IF EXISTS(SELECT * FROM #SQLSRV_LOG)
BEGIN
	SET @TableHTML_sqlsrvlog =
    N'<H1>SQL Server Log</H1>' +
    N'<table border="1">' +
    N'<tr><th>Время события</th><th>Процесс</th>' +
    N'<th>Текст</th>' +
    N'</tr>' +
    CAST ( ( SELECT td = CONVERT(NVARCHAR(30),LogDate,113),
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

IF EXISTS(SELECT * FROM #SQLAGENT_LOG)
BEGIN
	SET @TableHTML_agentlog =
    N'<H1>SQL Server Agent Error Log</H1>' +
    N'<table border="1">' +
    N'<tr><th>Время события</th><th>Процесс</th>' +
    N'<th>Текст</th>' +
    N'</tr>' +
    CAST ( ( SELECT td = CONVERT(NVARCHAR(30),LogDate,113),
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

IF @TableHTML <> ''
BEGIN
	SET NOCOUNT ON;
	EXEC msdb.dbo.sp_send_dbmail 
				@profile_name = 'DBA_Profile',
				@recipients = 'v.aleev@voz.ru',
				@subject = @Subj,
				@body = @TableHTML,
				@body_format = 'HTML' ;
END

DROP TABLE #SQLSRV_LOG;
DROP TABLE #SQLAGENT_LOG;
