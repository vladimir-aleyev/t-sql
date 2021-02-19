/*
This counter monitors the number of full scans on base tables or indexes.
Values greater than 1 or 2 indicate that we are having table / Index page scans.
If we see high CPU then we need to investigate this counter. Otherwise, if the full scans are on small tables, we can ignore this counter.
Two of the main causes of high Full Scans/sec are missing indexes and too many rows requested.
Queries with missing indexes or too many rows requested will have a large number of logical reads and an increased CPU time.
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
	object_name LIKE '%:Access Methods%' AND 
	counter_name = 'Full Scans/sec';
	

-- wait for 5 seconds
WAITFOR DELAY '00:00:05';

-- get second sample
SELECT 
	@value2 = cntr_value, 
	@time2 = getdate()
FROM
	sys.dm_os_performance_counters
WHERE 
	object_name LIKE '%:Access Methods%' AND 
	counter_name = 'Full Scans/sec';

-- calculate full scans per second
SELECT
	(@value2 - @value1) / datediff(ss,@time1,@time2) [Full Scans/sec];