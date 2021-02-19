/*
The total size of the database data files.
*/

SELECT 
	cntr_value 
FROM
	sys.dm_os_performance_counters
WHERE 
	object_name LIKE '%:Databases%' AND 
	counter_name = 'Data File(s) Size (KB)' AND 
	instance_name = '_Total';
