/*
The average wait time in milliseconds of each lock request that had a wait time.
This value should be kept under 500ms. Wait times over 500ms may indicate blocking.
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
	counter_name = 'Average Wait Time (ms)' AND 
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
	counter_name = 'Average Wait Time (ms)' AND 
	instance_name = '_Total';

-- calculate average lock wait time
SELECT
	(@value2 - @value1) / datediff(ss,@time1,@time2) [Average Wait Time (ms)];
