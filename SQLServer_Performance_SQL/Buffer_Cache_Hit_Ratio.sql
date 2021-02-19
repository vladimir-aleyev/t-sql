/*
This SQL Server Buffer Cache Hit Ratio counter indicates how often SQL Server goes to the buffer, not the hard disk, to get data.
In OLTP applications, this ratio should exceed 90%, and ideally be over 99%.
If your buffer cache hit ratio is lower than 90%, you need to go out and buy more RAM as soon as possible.
If the ratio is between 90% and 99%, then you should seriously consider purchasing more RAM, as the closer you get to 99%, the faster your SQL Server will perform.
In some cases, if your database is very large, you may not be able to get close to 99%, even if you put the maximum amount of RAM in your server.
All you can do is add as much as you can, and then live with the consequences. 
In OLAP applications, the ratio can be much less because of the nature of how OLAP works.
In any case, more RAM should increase the performance of SQL Server.
*/

SELECT 
	CONVERT(decimal(15,2), 100.0 * t.CacheHitRatio / t.CacheHitRatioBase)
FROM 
	(
		SELECT
		(
			SELECT 
				cntr_value AS 'CacheHitRatio' 
			FROM 
				sys.dm_os_performance_counters
			WHERE 
				object_name LIKE '%:Buffer Manager%' AND 
				counter_name = 'Buffer cache hit ratio' 
		) AS 'CacheHitRatio',  
		(
			SELECT 
				cntr_value AS 'CacheHitRatioBase' 
			FROM 
				sys.dm_os_performance_counters
			WHERE 
				object_name LIKE '%:Buffer Manager%' AND 
				counter_name = 'Buffer cache hit ratio base' 
		) AS 'CacheHitRatioBase'
	) AS t