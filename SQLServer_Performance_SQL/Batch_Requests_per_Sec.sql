/*
This counter measures the number of batch requests that SQL Server receives per second, and generally follows in step to how busy your server's CPUs are.
Generally speaking, over 1000 batch requests per second indicates a very busy SQL Server, and could mean that if you are not already experiencing a CPU bottleneck,
 that you may be experiencing one soon.
Of course, this is a relative number, and the bigger your hardware, the more batch requests per second SQL Server can handle.
From a network bottleneck approach, a typical 100Mbs network card is only able to handle about 3000 batch requests per second.
If you have a server that is this busy, you may need to have two or more network cards, or go to a 1Gbs network card. 
Note: Sometimes low batch requests/sec can be misleading. If there were a SQL statements/sec counter, this would be a more accurate measure of the amount of SQL Server activity.
For example, an application may call only a few stored procedures, yet each stored procedure does a lot of work.
In that case, we will see a low number for batch requests/sec but each stored procedure (one batch) will execute many SQL statements that drive CPU and other resources.
As a result, many counter thresholds based on the number of batch requests/sec will seem to identify issues,
 because the batch requests on such a server are unusually low for the level of activity on the server.  
We cannot conclude that a SQL Server is not active simply by looking at only batch requests/sec.
Rather, you have to do more investigation before deciding there is no load on the server.
If the average number of batch requests/sec is below 5 and other counters (such as SQL Server processor utilization) confirm the absence of significant activity,
 then there is not enough of a load to make any recommendations or identify issues regarding scalability.
Note: Set this threshold according to your environment.
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
	counter_name = 'Batch Requests/sec';
	

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
	counter_name = 'Batch Requests/sec';

-- calculate batch requests per second
SELECT
	(@value2 - @value1) / datediff(ss,@time1,@time2) [Batch Requests/sec];
