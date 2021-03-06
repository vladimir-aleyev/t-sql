SELECT			
	r.session_id, 
	se.host_name, 
	se.login_name, 
	db_name(r.database_id) AS db_name, 
	r.status, 
	r.command,
					CAST(((DATEDIFF(s,start_time,GetDate()))/3600) as varchar) + ' hour(s), '
					+ CAST((DATEDIFF(s,start_time,GetDate())%3600)/60 as varchar) + 'min, '
					+ CAST((DATEDIFF(s,start_time,GetDate())%60) as varchar) + ' sec' as running_time,
					r.blocking_session_id AS blk_by, r.open_transaction_count AS open_tran_count, r.wait_type,
					object_name = OBJECT_SCHEMA_NAME(s.objectid,s.dbid) + '.' + OBJECT_NAME(s.objectid, s.dbid),
 					program_name = se.program_name, p.query_plan AS query_plan,
					sql_text = SUBSTRING(s.text,
						1+(CASE WHEN r.statement_start_offset = 0 THEN 0 ELSE r.statement_start_offset/2 END),
						1+(CASE WHEN r.statement_end_offset = -1 THEN DATALENGTH(s.text) ELSE r.statement_end_offset/2 END - (CASE WHEN r.statement_start_offset = 0 THEN 0 ELSE r.statement_start_offset/2 END))),
					r.sql_handle, mg.requested_memory_kb, mg.granted_memory_kb, mg.ideal_memory_kb, mg.query_cost,
					((((ssu.user_objects_alloc_page_count + (SELECT SUM(tsu.user_objects_alloc_page_count) FROM sys.dm_db_task_space_usage tsu WHERE tsu.session_id = ssu.session_id)) -
					(ssu.user_objects_dealloc_page_count + (SELECT SUM(tsu.user_objects_dealloc_page_count) FROM sys.dm_db_task_space_usage tsu WHERE tsu.session_id = ssu.session_id)))*8)/1024) AS user_obj_in_tempdb_MB,
					((((ssu.internal_objects_alloc_page_count + (SELECT SUM(tsu.internal_objects_alloc_page_count) FROM sys.dm_db_task_space_usage tsu WHERE tsu.session_id = ssu.session_id)) -
					(ssu.internal_objects_dealloc_page_count + (SELECT SUM(tsu.internal_objects_dealloc_page_count) FROM sys.dm_db_task_space_usage tsu WHERE tsu.session_id = ssu.session_id)))*8)/1024) AS internal_obj_in_tempdb_MB,
					r.cpu_time,	start_time, percent_complete,		
					CAST((estimated_completion_time/3600000) as varchar) + ' hour(s), '
					+ CAST((estimated_completion_time %3600000)/60000 as varchar) + 'min, '
					+ CAST((estimated_completion_time %60000)/1000 as varchar) + ' sec' as est_time_to_go,
					dateadd(second,estimated_completion_time/1000, getdate()) as est_completion_time
FROM   
	sys.dm_exec_requests r WITH (NOLOCK)  
JOIN
	sys.dm_exec_sessions se WITH (NOLOCK) ON r.session_id = se.session_id
LEFT OUTER JOIN 
	sys.dm_exec_query_memory_grants mg WITH (NOLOCK) ON r.session_id = mg.session_id AND r.request_id = mg.request_id
LEFT OUTER JOIN 
	sys.dm_db_session_space_usage ssu WITH (NOLOCK) ON r.session_id = ssu.session_id
OUTER APPLY 
	sys.dm_exec_sql_text(r.sql_handle) s 
OUTER APPLY 
	sys.dm_exec_query_plan(r.plan_handle) p
WHERE 
	r.session_id <> @@SPID 
	AND se.is_user_process = 1
ORDER BY
	start_time;

--  exec sp_who3
--  exec sp_who2