/*
The number of lock requests that end up in a deadlock per second.
This value should less than 1.
*/

DECLARE @time1 DATETIME;
DECLARE @time2 DATETIME;
DECLARE @value1 BIGINT;
DECLARE @value2 BIGINT;

-- get first sample
SELECT 
	@value1 = cntr_value, 
	@time1 = getdate()
FROM
	sys.dm_os_performance_counters
WHERE 
	object_name LIKE '%:Locks%' AND 
	counter_name = 'Number of Deadlocks/sec' AND 
	instance_name = '_Total';
	

-- wait for 5 seconds
WAITFOR DELAY '00:00:05';

-- get second sample
SELECT 
	@value2 = cntr_value, 
	@time2 = getdate()
FROM
	sys.dm_os_performance_counters
WHERE 
	object_name LIKE '%:Locks%' AND 
	counter_name = 'Number of Deadlocks/sec' AND 
	instance_name = '_Total';

-- calculate deadlocks per second
SELECT
	(@value2 - @value1) / datediff(ss,@time1,@time2) [Number of Deadlocks/sec];