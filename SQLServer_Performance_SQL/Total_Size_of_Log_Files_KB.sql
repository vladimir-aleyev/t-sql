/*
The total size of the database log files.
*/

SELECT 
	cntr_value AS 'Total Size (KB) of Log Files'
FROM
	sys.dm_os_performance_counters
WHERE 
	object_name LIKE '%:Databases%' AND 
	counter_name = 'Log File(s) Size (KB)' AND 
	instance_name = '_Total';
