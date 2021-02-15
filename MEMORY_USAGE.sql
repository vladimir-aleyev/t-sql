--SELECT
--	resource_semaphore_id,	-- Nonunique ID of the resource semaphore. 0 for the regular resource semaphore and 1 for the small-query resource semaphore.
--	target_memory_kb,		-- Grant usage target in kilobytes.
--	max_target_memory_kb,	-- Maximum potential target in kilobytes. NULL for the small-query resource semaphore.
--	total_memory_kb,		-- Memory held by the resource semaphore in kilobytes. 
--							-- If the system is under memory pressure or if forced minimum memory is granted frequently, this value can be larger than the target_memory_kb or max_target_memory_kb values.
--							-- Total memory is a sum of available and granted memory.
--	available_memory_kb,	-- Memory available for a new grant in kilobytes.
--	granted_memory_kb,		-- Total granted memory in kilobytes.
--	used_memory_kb,			-- Physically used part of granted memory in kilobytes.
--	grantee_count,			-- !!!	Number of active queries that have their grants satisfied. !!! --
--	waiter_count,			-- !!!	Number of queries waiting for grants to be satisfied.	!!! --
--	timeout_error_count,	-- Total number of time-out errors since server startup. NULL for the small-query resource semaphore.
--	forced_grant_count,		-- Total number of forced minimum-memory grants since server startup. NULL for the small-query resource semaphore.
--	pool_id					-- ID of the resource pool to which this resource semaphore belongs.
--FROM
--	sys.dm_exec_query_resource_semaphores;


---------Find all queries waiting in the memory queue ----------------
--SELECT * FROM sys.dm_exec_query_memory_grants where grant_time is null
----------------------------------------------------------------------

-----------------------------------------------------
SELECT
	mg.session_id,				-- ID (SPID) of the session where this query is running.
	ts.text,					-- Text of the SQL query. 
	--ps.query_plan,			-- TOO HEAVY --
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
CROSS APPLY
	sys.dm_exec_sql_text(mg.sql_handle) AS ts
--CROSS APPLY
	--sys.dm_exec_query_plan(mg.plan_handle) AS ps

INNER JOIN
	sys.dm_exec_sessions AS ss
	ON mg.session_id = ss.session_id
 ORDER BY
	mg.requested_memory_kb DESC
	


--CREATE TABLE msdb.dbo.MEMORY_USAGE_log
--(
--	PostTime DATETIME DEFAULT GETDATE(),
--	session_id SMALLINT NOT NULL,
--	sql_text NVARCHAR(MAX) NULL,
--	login_name NVARCHAR(128) NULL,
--	program_name NVARCHAR(128) NULL,
--	host_name NVARCHAR(128) NULL,
--	dop SMALLINT NULL,				
--	request_time DATETIME NULL,
--	grant_time DATETIME NULL,	
--	requested_memory_kb BIGINT NULL,
--	granted_memory_kb BIGINT NULL,
--	required_memory_kb BIGINT NULL,
--	used_memory_kb BIGINT NULL,	
--	max_used_memory_kb BIGINT NULL,	
--	query_cost FLOAT NULL,	
--	timeout_sec INT NULL
--)


