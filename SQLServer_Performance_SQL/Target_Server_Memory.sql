/*
The total amount of dynamic memory the server can consume.
*/

SELECT 
	cntr_value	
FROM
	sys.dm_os_performance_counters
WHERE 
	object_name LIKE '%:Memory Manager%' AND 
	counter_name = 'Target Server Memory (KB)'

