DECLARE @session SMALLINT
DECLARE @sql VARCHAR(1000)

SELECT TOP(1)
	@session = mg.session_id
FROM
	sys.dm_exec_query_memory_grants AS mg
CROSS APPLY
	sys.dm_exec_sql_text(mg.sql_handle) AS ts
INNER JOIN
	sys.dm_exec_sessions AS ss
	ON mg.session_id = ss.session_id
ORDER BY
	mg.requested_memory_kb DESC

DECLARE @buffer_results TABLE
			(
				EventType VARCHAR(30),
				Parameters INT,
				EventInfo NVARCHAR(4000),
				start_time DATETIME,
				session_number INT IDENTITY(1,1) NOT NULL PRIMARY KEY
			);
INSERT @buffer_results(EventType, Parameters, EventInfo) EXEC sp_executesql N'DBCC INPUTBUFFER(@s) WITH NO_INFOMSGS;',N'@s SMALLINT',@session;

SELECT @session AS session_id,EventType,Parameters,EventInfo AS sql_command FROM @buffer_results