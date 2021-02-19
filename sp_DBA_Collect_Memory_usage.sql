CREATE PROCEDURE dbo.sp_DBA_CollectMemoryUsage
AS
INSERT INTO
	[dbo].[MEMORY_USAGE_log]
(
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
	mg.session_id,				-- ID (SPID) of the session where this query is running.
	ts.text,					-- Text of the SQL query. 
	ss.login_name,
	ss.program_name,
	ss.host_name,
	mg.dop,						-- Degree of parallelism of this query.
	mg.request_time,			-- Date and time when this query requested the memory grant.
	mg.grant_time,				-- !!!	Date and time when memory was granted for this query. !!! NULL if memory is not granted yet !!!.
	mg.requested_memory_kb,		-- !!!	Total requested amount of memory in kilobytes !!!.
	mg.granted_memory_kb,		-- !!!	Total amount of memory actually granted in kilobytes	!!!. 
								-- Can be NULL if the memory is not granted yet. 
								-- For a typical situation, this value should be the same as requested_memory_kb. For index creation, the server may allow additional on-demand memory beyond initially granted memory.
	mg.required_memory_kb,		-- Minimum memory required to run this query in kilobytes. requested_memory_kb is the same or larger than this amount.
	mg.used_memory_kb,			-- Physical memory used at this moment in kilobytes.
	mg.max_used_memory_kb,		-- Maximum physical memory used up to this moment in kilobytes.
	mg.query_cost,				-- Estimated query cost.
	mg.timeout_sec--,			-- Time-out in seconds before this query gives up the memory grant request.
FROM
	sys.dm_exec_query_memory_grants AS mg
CROSS APPLY
	sys.dm_exec_sql_text(mg.sql_handle) AS ts
INNER JOIN
	sys.dm_exec_sessions AS ss
	ON mg.session_id = ss.session_id
 ORDER BY
	mg.requested_memory_kb DESC