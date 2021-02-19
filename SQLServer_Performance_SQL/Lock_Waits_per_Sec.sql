/*
This counter reports how many times users waited to acquire a lock over the past second.
Note that while you are actually waiting on the lock, this is not reflected in this counter.
It gets incremented only when you “wake up” after waiting on the lock.
If this value is nonzero, then it is an indication that there is at least some level of blocking occurring.
If you combine this with the Lock Wait Time counter, you can get some idea of how long the blocking lasted.
A zero value for this counter can definitively rule out blocking as a potential cause; 
a nonzero value will require looking at other information to determine whether it is significant.
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
	counter_name = 'Lock Waits/sec' AND 
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
	counter_name = 'Lock Waits/sec' AND 
	instance_name = '_Total';

-- calculate lock waits per second
SELECT
	(@value2 - @value1) / datediff(ss,@time1,@time2) [Lock Waits/sec];