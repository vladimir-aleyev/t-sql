/*
The number of users currently connected to the SQL Server. 
Note: It is recommended to review this counter along with “Batch Requests/Sec”.
A surge in “user connections” may result in a surge of “Batch Requests/Sec”.
So if there is a disparity (one going up and the other staying flat or going down), then that may be a cause for concern.
With a blocking problem, for example, you might see user connections, lock waits, and lock wait time all increase, while batch requests/sec decrease.
*/
SELECT 
	cntr_value 
FROM 
	sys.dm_os_performance_counters
WHERE 
	object_name LIKE '%:General Statistics%' AND 
	counter_name = 'User Connections'