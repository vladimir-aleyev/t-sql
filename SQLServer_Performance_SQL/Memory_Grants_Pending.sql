/*
Total number of processes waiting to acquire a workspace memory grant.
*/

SELECT 
	cntr_value
FROM
	sys.dm_os_performance_counters
WHERE 
	object_name LIKE '%:Memory Manager%' AND 
	counter_name = 'Memory Grants Pending'
