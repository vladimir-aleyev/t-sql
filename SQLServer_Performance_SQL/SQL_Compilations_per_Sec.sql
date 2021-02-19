/*
The number of SQL compilations that occur each second.
Values higher than 100 indicate a high proportion of adhoc queries and may be using up valuable CPU time.
Solutions include rewriting adhoc queries as stored procedures and using sp_executeSQL.
This value should be as low as possible, preferably under 10% of the Batch Requests/sec.
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
	object_name LIKE '%:SQL Statistics%' AND 
	counter_name = 'SQL Compilations/sec'
	

-- wait for 5 seconds
WAITFOR DELAY '00:00:05';

-- get second sample
SELECT 
	@value2 = cntr_value, 
	@time2 = getdate()
FROM
	sys.dm_os_performance_counters
WHERE 
	object_name LIKE '%:SQL Statistics%' AND 
	counter_name = 'SQL Compilations/sec'

-- calculate sql compilations per second
SELECT
	(@value2 - @value1) / datediff(ss,@time1,@time2) [SQL Compilations/sec];