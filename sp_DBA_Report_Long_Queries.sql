USE [master]
GO

/****** Object:  StoredProcedure [dbo].[DBA_Report_Long_Queries]    Script Date: 05.04.17 17:29:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		V. Aleev
-- Create date: 01.10.2015
-- Description:	Report of long running queries, num of hours as param.
-- =============================================
CREATE PROCEDURE [dbo].[DBA_Report_Long_Queries]
	@num_hours TINYINT = 1,
	@recip VARCHAR(255),
	@cc_recip VARCHAR(255) = ''
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @TableHTML NVARCHAR(MAX);
	DECLARE @Subj NVARCHAR(128);

	SET @Subj = @@SERVERNAME + ' Queries running more tnan ' + CAST(@num_hours AS NVARCHAR(3)) + ' hours';


	IF (SELECT OBJECT_ID(N'#LONG_QUERIES')) IS NOT NULL
		DROP TABLE #LONG_QUERIES


	SELECT 
		CONVERT(VARCHAR(25),(GETDATE() - [sessions].[last_request_start_time]),8) AS DURATION,
		[sessions].[session_id] AS [SESSION ID] ,
		[sessions].[login_name] AS [LOGIN NAME],
		[sessions].[host_name] AS [HOST NAME],
		[SQL_TEXT].[text] AS [SQL_TEXT],
		[requests].[cpu_time] AS [CPU TIME],
		[sessions].[memory_usage] + COALESCE([requests].[granted_query_memory], 0) AS [MEMORY USAGE],
		[requests].[reads] AS [READS],
		[requests].[writes] AS [WRITES],
		[requests].[logical_reads] AS [LOGICAL READS],
		[sessions].[last_request_start_time] AS [START TIME]
	INTO #LONG_QUERIES
	FROM
		sys.dm_exec_sessions [sessions]
		JOIN
		sys.dm_exec_requests [requests]
		ON
		[sessions].[session_id] = [requests].[session_id]
		CROSS APPLY
		sys.dm_exec_sql_text([requests].[sql_handle]) AS [SQL_TEXT]
	WHERE
		[sessions].[status] = 'running'
		AND
		[sessions].[last_request_start_time] < DATEADD(hh,-@num_hours,GETDATE())

	IF EXISTS (SELECT DURATION FROM #LONG_QUERIES )
	BEGIN
		SET @TableHTML = 
		N'<H1>' +@@SERVERNAME+ ' LONG RUNNING QUERIES</H1>' +
		N'<table border="1">' +
		N'<tr><th>DURATION</th><th>SESSION ID</th><th>LOGIN NAME</th><th>HOST NAME</th><th>SQL_TEXT</th><th>CPU TIME</th><th>MEMORY USAGE</th><th>READS</th><th>WRITES</th><th>LOGICAL READS</th><th>START TIME</th>'
		+
		N'</tr>' +
		CAST ( ( SELECT td = [DURATION],
						'',
						td = [SESSION ID] ,
						'',
						td = [LOGIN NAME],
						'',
						td = ISNULL([HOST NAME],''),
						'',
						td = SUBSTRING([SQL_TEXT],1,100)+' ...',
						'',
						td = [CPU TIME],
						'',
						td = [MEMORY USAGE],
						'',
						td = [READS],
						'',
						td = [WRITES],
						'',
						td = [LOGICAL READS],
						'',
						td = [START TIME],
						''
				  FROM #LONG_QUERIES ORDER BY [DURATION] DESC
				  FOR XML PATH('tr'), TYPE 
		) AS NVARCHAR(MAX) ) +
		N'</table>' 

	END

	IF @TableHTML IS NOT NULL
	BEGIN
		SET NOCOUNT ON;
		EXEC msdb.dbo.sp_send_dbmail 
					@profile_name = 'DBA_Profile',
					@recipients = @recip,
					@copy_recipients  = @cc_recip,
					@subject = @Subj,
					@body = @TableHTML,
					@body_format = 'HTML';

		EXEC [master].[dbo].[sp_WhoIsActive]
					@get_task_info = 2,
					@get_full_inner_text = 1,
					@get_outer_command = 1,
					@get_additional_info = 1,
					@DESTINATION_TABLE = 'msdb.dbo.DBA_WhoIsActive'
	END

DROP TABLE #LONG_QUERIES;
		
END

GO


