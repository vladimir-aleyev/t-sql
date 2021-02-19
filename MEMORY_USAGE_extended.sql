DECLARE @t_session TABLE (session_id INT PRIMARY KEY CLUSTERED)
DECLARE @session SMALLINT
DECLARE @sql VARCHAR(1000)

DECLARE @MEMORY_USAGE_log TABLE (
	[session_id] [smallint] NOT NULL,
	[sql_text] [nvarchar](max) NULL,
	[sql_command] [nvarchar](max) NULL,
	[login_name] [nvarchar](128) NULL,
	[program_name] [nvarchar](128) NULL,
	[host_name] [nvarchar](128) NULL,
	[dop] [smallint] NULL,
	[request_time] [datetime] NULL,
	[grant_time] [datetime] NULL,
	[requested_memory_kb] [bigint] NULL,
	[granted_memory_kb] [bigint] NULL,
	[required_memory_kb] [bigint] NULL,
	[used_memory_kb] [bigint] NULL,
	[max_used_memory_kb] [bigint] NULL,
	[query_cost] [float] NULL,
	[timeout_sec] [int] NULL
)
INSERT INTO @MEMORY_USAGE_log(
	[session_id],
	[sql_text],
	[login_name],
	[program_name],
	[host_name],
	[dop],
	[request_time],
	[grant_time],
	[requested_memory_kb],
	[granted_memory_kb],
	[required_memory_kb],
	[used_memory_kb],
	[max_used_memory_kb],
	[query_cost],
	[timeout_sec]
)
SELECT
	mg.session_id,				
	ts.text,					 
	ss.login_name,
	ss.program_name,
	ss.host_name,
	mg.dop,						
	mg.request_time,			
	mg.grant_time,			
	mg.requested_memory_kb,	
	mg.granted_memory_kb,	 
	mg.required_memory_kb,	
	mg.used_memory_kb,		
	mg.max_used_memory_kb,	
	mg.query_cost,			
	mg.timeout_sec
FROM
	sys.dm_exec_query_memory_grants AS mg
CROSS APPLY
	sys.dm_exec_sql_text(mg.sql_handle) AS ts
INNER JOIN
	sys.dm_exec_sessions AS ss
	ON mg.session_id = ss.session_id
 ORDER BY
	mg.requested_memory_kb DESC

INSERT INTO @t_session(session_id)
SELECT
	session_id 
FROM
	@MEMORY_USAGE_log

DECLARE @buffer_results TABLE
			(
				EventType VARCHAR(30),
				Parameters INT,
				EventInfo NVARCHAR(4000),
				start_time DATETIME,
				session_number INT IDENTITY(1,1) NOT NULL PRIMARY KEY
			);

DECLARE session_cur CURSOR LOCAL FAST_FORWARD FOR SELECT session_id FROM @t_session

OPEN session_cur  

FETCH NEXT FROM session_cur INTO @session

WHILE @@FETCH_STATUS = 0  
BEGIN 
	BEGIN TRY
	DELETE FROM @buffer_results;
	INSERT
		@buffer_results(
						EventType,
						Parameters,
						EventInfo)
		EXEC
			sp_executesql N'DBCC INPUTBUFFER(@s) WITH NO_INFOMSGS;',N'@s SMALLINT',@session;
		
		UPDATE
			@MEMORY_USAGE_log
		SET
			sql_command = br.EventInfo
		FROM
			@buffer_results AS br
		WHERE
			session_id = @session
	FETCH NEXT FROM session_cur INTO @session
	END TRY
	BEGIN CATCH
	END CATCH
END

CLOSE session_cur
DEALLOCATE session_cur

SELECT * FROM @MEMORY_USAGE_log

