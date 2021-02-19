/*
The length of time in seconds the transaction that has been running the longest has been active.
*/

SELECT 
	cntr_value
FROM
	sys.dm_os_performance_counters
WHERE 
	object_name LIKE '%:Transactions%' AND 
	counter_name = 'Longest Transaction Running Time'
