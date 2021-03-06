---
SELECT max_workers_count FROM sys.dm_os_sys_info
---

---
SELECT
	AVG (work_queue_count)
FROM
	sys.dm_os_schedulers
WHERE
	status = 'VISIBLE ONLINE'
---

---
SELECT 
	SUM(current_workers_count) as [Current worker thread] 
FROM
	sys.dm_os_schedulers
---

---
---сведения о системных задачах, породивших дополнительные потоки.
---
SELECT  
	s.session_id,  
	r.command,  
	r.status,  
	r.wait_type,  
	r.scheduler_id,  
	w.worker_address,  
	w.is_preemptive,  
	w.state,  
	t.task_state,  
	t.session_id,  
	t.exec_context_id,  
	t.request_id  
FROM
	sys.dm_exec_sessions AS s  
INNER JOIN
	sys.dm_exec_requests AS r  
    ON s.session_id = r.session_id  
INNER JOIN
	sys.dm_os_tasks AS t
    ON r.task_address = t.task_address  
INNER JOIN
	sys.dm_os_workers AS w  
    ON t.worker_address = w.worker_address  
WHERE s.is_user_process = 0; 
---

---
SELECT 
	SUM(current_tasks_count) AS current_tasks_count,
	SUM(runnable_tasks_count) AS runnable_tasks_count,
	SUM(current_workers_count) AS current_workers_count,
	SUM(active_workers_count) AS active_workers_count,
	SUM(work_queue_count) AS work_queue_count,
	SUM(pending_disk_io_count) AS pending_disk_io_count
FROM
	sys.dm_os_schedulers
WHERE
	status = 'VISIBLE ONLINE'
---
