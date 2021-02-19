---This first thing to check if CPU is at 100% is to look for parallel queries:
-- Tasks running in parallel (filtering out MARS requests below):
select
	*
from
	sys.dm_os_tasks as t
where
	t.session_id in (
						select
							t1.session_id
						from
							sys.dm_os_tasks as t1
						group by
							t1.session_id
						having
							count(*) > 1
							and
							min(t1.request_id) = max(t1.request_id))


-- Requests running in parallel:

select
	r.session_id,
	r.start_time,
	r.status,
	r.command,
	r.sql_handle,
	r.plan_handle,
	DB_NAME(r.database_id) AS db,
	USER_NAME(r.user_id) AS username,
	r.blocking_session_id,
	r.wait_type,
	r.wait_time,
	r.last_wait_type,
	r.cpu_time,
	r.reads,
	r.writes,
	r.logical_reads,
	--t.*,
	sql_command.text
from
	sys.dm_exec_requests as r
join
	(
		select t1.session_id, min(t1.request_id)
		from sys.dm_os_tasks as t1
		group by t1.session_id
		having count(*) > 1
		and min(t1.request_id) = max(t1.request_id)
	) 
	as t(session_id, request_id)
on r.session_id = t.session_id
and r.request_id = t.request_id
CROSS APPLY
sys.dm_exec_sql_text(r.sql_handle) AS sql_command

-----------------
--select * from sys.dm_os_tasks o
--	INNER JOIN 
--	sys.dm_os_schedulers s
--	ON o.scheduler_id = s.scheduler_id