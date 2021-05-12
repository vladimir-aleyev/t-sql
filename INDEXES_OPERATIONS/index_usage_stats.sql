SELECT 
	DB_NAME(iu.database_id) AS DBNAME,
	OBJECT_NAME(iu.[object_id]) AS OBJECTNAME,
	idxs.[name] AS INDEXNAME,
	iu.user_seeks,
	iu.user_scans,
	iu.user_lookups,
	iu.user_updates,
	iu.last_user_seek,
	iu.last_user_scan,
	iu.last_user_lookup,
	iu.last_user_update
	--,iu.* 
FROM 
	sys.dm_db_index_usage_stats AS iu
INNER JOIN
	sys.indexes idxs
ON 
	iu.[object_id] = idxs.[object_id]
AND
	iu.[index_id] = idxs.[index_id]
ORDER BY
	iu.[database_id],
	iu.[object_id];