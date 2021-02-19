/*
The number of tables in the database that have one or more out-of-order index pages.
*/

DECLARE @db_id SMALLINT;
SET @db_id = DB_ID(N'master');
SELECT
	count (IPS.avg_fragmentation_in_percent) as [Number of fragmented tables]
FROM
	sys.dm_db_index_physical_stats(@db_id, NULL, NULL, NULL , 'DETAILED') IPS
WHERE
	IPS.avg_fragmentation_in_percent > 0
