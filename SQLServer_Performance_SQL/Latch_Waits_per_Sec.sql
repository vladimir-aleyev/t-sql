/*
This is the number of latch requests that could not be granted immediately.
In other words, these are the amount of latches in a one second period that had to wait.
Latches are light-weight synchronization constructs that are designed to protect the physical integrity of a page in a similar way to how locks protect the logical consistency of rows.
They're taken any time something wants to modify a page, be it moving the page from disk to memory or via versa, writing a record onto a page, or changing a page's metadata.
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
	object_name LIKE '%:Latches%' AND 
	counter_name = 'Latch Waits/sec';
	

-- wait for 5 seconds
WAITFOR DELAY '00:00:05';

-- get second sample
SELECT 
	@value2 = cntr_value, 
	@time2 = getdate()
FROM
	sys.dm_os_performance_counters
WHERE 
	object_name LIKE '%:Latches%' AND 
	counter_name = 'Latch Waits/sec';

-- calculate latch waits per second
SELECT
	(@value2 - @value1) / datediff(ss,@time1,@time2) [Latch Waits/sec];

