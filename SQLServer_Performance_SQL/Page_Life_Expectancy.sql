/*
The time in seconds before the average data page is removed from the cache buffer. 
If the average page life falls below 300 seconds, this may indicate that your SQL server may require more RAM to improve performance.
*/

SELECT 
	cntr_value AS 'Page life expectancy'
FROM
	sys.dm_os_performance_counters
WHERE 
	 object_name LIKE '%:Buffer Manager%' AND 
	 counter_name = 'Page life expectancy'
