/*
The Total Server Memory is the current amount of memory that SQL Server is using.
If this counter is still growing, the server has not yet reached its steady-state, and it is still trying to populate the cache and get pages loaded into memory.
Performance will likely be somewhat slower during this time since more disk I/O is required at this stage.
This behavior is normal.
Eventually Total Server Memory should approximate Target Server Memory.
Set a threshold according to your environment.
*/

SELECT 
	cntr_value
FROM
	sys.dm_os_performance_counters
WHERE 
	object_name LIKE '%:Memory Manager%' AND 
	counter_name = 'Total Server Memory (KB)'