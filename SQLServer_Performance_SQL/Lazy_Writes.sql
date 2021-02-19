/*
Number of buffers written per second by the lazy writer system process.
The lazy writer flushes out old, dirty buffer cache pages to make them available for reuse.
If the value of this counter is higher than 20, then the server could use additional RAM.
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
	object_name LIKE '%:Buffer Manager%' AND 
	counter_name = 'Lazy writes/sec';
	

-- wait for 5 seconds
WAITFOR DELAY '00:00:05';

-- get second sample
SELECT 
	@value2 = cntr_value, 
	@time2 = getdate()
FROM
	sys.dm_os_performance_counters
WHERE 
	object_name LIKE '%:Buffer Manager%' AND 
	counter_name = 'Lazy writes/sec';

-- calculate lazy writes per second
SELECT
	(@value2 - @value1) / datediff(ss,@time1,@time2) [Lazy writes/sec];