/*
Number of physical database page reads issued.
80 – 90 per second is normal; anything that is above indicates indexing or memory constraint.
Values for this counter will vary between database applications, but this information is useful when determining if SQL Server is the primary application using the disk.
If the Buffer Manager page read-writes are low but disk-queue lengths are high, there might be a disk bottleneck.
If the Page read-writes are higher than normal, a memory shortage is likely to exist.
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
	counter_name = 'Page reads/sec';
	

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
	counter_name = 'Page reads/sec';

-- calculate page reads per second
SELECT
	(@value2 - @value1) / datediff(ss,@time1,@time2) [Page reads/sec];