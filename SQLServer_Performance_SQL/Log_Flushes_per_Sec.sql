/*
The total number of log bytes flushed.
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
	object_name LIKE '%:Databases%' AND 
	counter_name = 'Log Flushes/sec' AND 
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
	object_name LIKE '%:Databases%' AND 
	counter_name = 'Log Flushes/sec' AND 
	instance_name = '_Total';

-- calculate log flushes per second
SELECT
	(@value2 - @value1) / datediff(ss,@time1,@time2) [Log Flushes/sec];
