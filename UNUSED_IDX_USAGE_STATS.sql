/*
If you see indexes where there are no seeks, scans or lookups,
but there are updates this means that SQL Server has not used the index to satisfy a query
but still needs to maintain the index.
*/

SELECT
	DB_NAME([STATS].database_id) AS [DATABASE_NAME], 
	'DROP INDEX ',
	[IDX].name AS [INDEX_NAME],
	'ON ',
	OBJECT_NAME([STATS].object_id) AS [TABLE_NAME],
	[IDX].type_desc,
	[STATS].index_id,
	[STATS].user_seeks,
	[STATS].user_scans,
	[STATS].user_lookups,
	[STATS].user_updates,
	[STATS].last_user_seek,
	[STATS].last_user_scan,
	[STATS].last_user_lookup,
	[STATS].last_user_update
FROM
	sys.dm_db_index_usage_stats [STATS]
INNER JOIN
	sys.indexes [IDX]
ON 
	[STATS].object_id = [IDX].object_id
	AND
	[STATS].index_id = [IDX].index_id
WHERE
	[STATS].database_id = DB_ID()
AND
	[STATS].user_seeks = 0
AND
	[STATS].user_scans = 0
AND
	[STATS].user_lookups = 0

