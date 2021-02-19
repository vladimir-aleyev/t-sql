-- GET UNUSED INDEXES THAT APPEAR IN THE INDEX USAGE STATS TABLE
DECLARE @MinimumPageCount int
SET @MinimumPageCount = 500

SELECT	Databases.name AS [Database], 
	object_name(Indexes.object_id) AS [Table],					
	Indexes.name AS [Index],		
	PhysicalStats.page_count as [Page_Count],
	--(PhysicalStats.page_count * 8 / 1024.0) AS [Total Size (MB)],
	PhysicalStats.avg_fragmentation_in_percent AS [Frag %],
	--CONVERT(decimal(18,2), PhysicalStats.page_count * 8 / 1024.0) AS [Total Size (MB)],
	--CONVERT(decimal(18,2), PhysicalStats.avg_fragmentation_in_percent) AS [Frag %],
	ParititionStats.row_count AS [Row Count],
	--PhysicalStats.page_count,
	ParititionStats.row_count
	--CONVERT(decimal(18,2), (PhysicalStats.page_count * 8.0 * 1024) / ParititionStats.row_count) AS [Index Size/Row (Bytes)]
	,UsageStats.*
FROM
	sys.dm_db_index_usage_stats UsageStats
	INNER JOIN sys.indexes Indexes
		ON Indexes.index_id = UsageStats.index_id
			AND Indexes.object_id = UsageStats.object_id
	INNER JOIN SYS.databases Databases
		ON Databases.database_id = UsageStats.database_id		
	INNER JOIN sys.dm_db_index_physical_stats (DB_ID(),NULL,NULL,NULL,NULL) 
			AS PhysicalStats
		ON PhysicalStats.index_id = UsageStats.Index_id	
			and PhysicalStats.object_id = UsageStats.object_id
	INNER JOIN SYS.dm_db_partition_stats ParititionStats
		ON ParititionStats.index_id = UsageStats.index_id
			and ParititionStats.object_id = UsageStats.object_id		
WHERE
	UsageStats.user_scans = 0
	AND
	UsageStats.user_seeks = 0
	-- ignore indexes with less than a certain number of pages of memory
	AND PhysicalStats.page_count > @MinimumPageCount
	-- Exclude primary keys, which should not be removed
	AND Indexes.type_desc != 'CLUSTERED'		
ORDER BY [Page_Count] DESC

-------
SELECT	db_name(st.database_id) AS [DATABASE_NAME], object_name(st.object_id) AS [TABLE_NAME], 
		idx.name,
		st.*
	
FROM
	sys.dm_db_index_usage_stats st
	JOIN
	sys.indexes idx
	ON st.index_id = idx.index_id AND st.object_id = idx.object_id
WHERE
	db_name(database_id) = 'autodoc_cross'
	--AND
	--object_name(st.object_id) = 'opa_price_data_tb'
	AND
	user_seeks = 0
	AND
	user_scans = 0
	and
	user_lookups = 0


SELECT * FROM sys.indexes WHERE index_id = 20

-------

---
select 
       --sum(record_count) as records,
       --sum(ghost_record_count) as ghost_records,
       --sum(version_ghost_record_count) as version_ghost_records
	   --
	  *
from
	sys.dm_db_index_physical_stats(db_id(), default /*69575286 object_id('<table_name>')*/, default, default, 'detailed')
where
	index_id = 1
	and
	index_level = 0
