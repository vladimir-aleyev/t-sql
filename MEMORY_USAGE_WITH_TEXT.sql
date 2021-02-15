SELECT
	mg.session_id,				-- ID (SPID) of the session where this query is running.
	ts.text,					-- Text of the SQL query. 
	CASE
		WHEN sp.stmt_start > 0 THEN SUBSTRING(ts.text, ((sp.stmt_start/2) + 1), (
																					CASE
																						WHEN sp.stmt_end = -1 THEN 2147483647
																						ELSE ((sp.stmt_end - sp.stmt_start)/2) + 1
																					END
																				)
												)
		ELSE RTRIM(LTRIM(ts.text))
	END AS sql_text,
	ss.login_name,
	ss.program_name,
	ss.host_name,
	--mg.request_id,			-- ID of the request. Unique in the context of the session.
	--mg.scheduler_id,			-- ID of the scheduler that is scheduling this query.
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
	--mg.resource_semaphore_id,	-- Non-unique ID of the resource semaphore on which this query is waiting.
								-- Note: This ID is unique in versions of SQL Server that are earlier than SQL Server 2008. 
								-- This change can affect troubleshooting query execution.
	--mg.queue_id,				-- ID of waiting queue where this query waits for memory grants. NULL if the memory is already granted.
	--mg.wait_order,			-- Sequential order of waiting queries within the specified queue_id. This value can change for a given query if other queries get memory grants or time out. NULL if memory is already granted.
	--mg.is_next_candidate,		-- Candidate for next memory grant. 1 = Yes, 0 = No , NULL = Memory is already granted.
	--mg.wait_time_ms,			-- Wait time in milliseconds. NULL if the memory is already granted.
	--mg.plan_handle,			-- Identifier for this query plan. Use sys.dm_exec_query_plan to extract the actual XML plan.
	--mg.sql_handle,			-- Identifier for Transact-SQL text for this query. Use sys.dm_exec_sql_text to get the actual Transact-SQL text.
	--mg.group_id,				-- ID for the workload group where this query is running.
	--mg.pool_id,				-- ID of the resource pool that this workload group belongs to.
	--mg.is_small,				-- When set to 1, indicates that this grant uses the small resource semaphore. When set to 0, indicates that a regular semaphore is used.
	--mg.ideal_memory_kb		-- Size, in kilobytes (KB), of the memory grant to fit everything into physical memory. This is based on the cardinality estimate.
FROM
	sys.dm_exec_query_memory_grants AS mg
INNER JOIN
	sys.sysprocesses sp
	ON mg.session_id = sp.spid
CROSS APPLY
	sys.dm_exec_sql_text(sp.sql_handle) AS ts
INNER JOIN
	sys.dm_exec_sessions AS ss
	ON mg.session_id = ss.session_id
 ORDER BY
	mg.requested_memory_kb DESC



