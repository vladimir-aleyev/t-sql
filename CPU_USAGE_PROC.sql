---1----
SELECT TOP 20 
	qs.sql_handle, 
	qs.execution_count, 
	qs.total_worker_time AS Total_CPU, 
	total_CPU_inSeconds = --Converted from microseconds 
		qs.total_worker_time/1000000, 
	average_CPU_inSeconds = --Converted from microseconds 
		(qs.total_worker_time/1000000) / qs.execution_count, 
	qs.total_elapsed_time, 
		total_elapsed_time_inSeconds = --Converted from microseconds 
	qs.total_elapsed_time/1000000, 
	st.text, 
	qp.query_plan 
FROM 
	sys.dm_exec_query_stats AS qs 
CROSS APPLY 
	sys.dm_exec_sql_text(qs.sql_handle) AS st 
CROSS APPLY
	sys.dm_exec_query_plan (qs.plan_handle) AS qp 
ORDER BY 
	qs.total_worker_time DESC

---2----
SELECT  
	r.session_id ,
	(Select CON.client_net_address From sys.dm_exec_connections AS CON where CON.session_id = r.session_id) Client_Address,
	OBJECT_NAME(qt.objectid, qt.dbid) ObjectName,
    r.[status] ,
    r.wait_type ,
    r.scheduler_id ,
    SUBSTRING(qt.[text], r.statement_start_offset / 2,
            ( CASE WHEN r.statement_end_offset = -1
                   THEN LEN(CONVERT(NVARCHAR(MAX), qt.[text])) * 2
                   ELSE r.statement_end_offset
              END - r.statement_start_offset ) / 2) AS [statement_executing] ,
    DB_NAME(qt.[dbid]) AS [DatabaseName] ,
    Object_NAME(qt.objectid) AS [ObjectName] ,
    r.cpu_time ,
    r.total_elapsed_time ,
    r.reads ,
    r.writes ,
    r.logical_reads ,
    r.plan_handle,
	qp.query_plan
FROM
	sys.dm_exec_requests AS r
CROSS APPLY 
	sys.dm_exec_sql_text(sql_handle) AS qt
CROSS apply 
	sys.dm_exec_query_plan (r.plan_handle) AS qp 
WHERE
	r.session_id > 50
ORDER BY
	r.cpu_time DESC
--------

SELECT * FROM sys.dm_exec_query_plan(0x05000A005DB0227E307EC840F101000001000000000000000000000000000000000000000000000000000000)

---3---
--First use this query to find out CU consuming queries.
select top 50 
    sum(qs.total_worker_time) as total_cpu_time, 
    sum(qs.execution_count) as total_execution_count,
    count(*) as  number_of_statements, 
    qs.plan_handle 
from 
    sys.dm_exec_query_stats qs
group by qs.plan_handle
order by sum(qs.total_worker_time) desc

--Look for queries which are using parallelism
--Look for excessive compilation and recomplilation
--Look for adhoc queries
--this query will give u queries causing lots of recompilation

---4---
select top 25
    sql_text.text,
	sql_plan.*,
    sql_handle,
    plan_generation_num,
    execution_count,
    sql_text.dbid,
    sql_text.objectid 
from 
    sys.dm_exec_query_stats a
    cross apply sys.dm_exec_sql_text(a.sql_handle) as sql_text
	cross apply sys.dm_exec_query_plan(a.plan_handle) as sql_plan
where 
    plan_generation_num > 1
order by plan_generation_num desc
--Plan generation no > 1 means query is recompiling

---
--DBCC FREEPROCCACHE
---