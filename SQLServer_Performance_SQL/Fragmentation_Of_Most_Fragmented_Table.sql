/*
The fragmentation percentage of the most fragmented table in the database.
Fragmentation occurs naturally because INSERT, UPDATE, and DELETE statements are not typically distributed equally among the table rows and its indexes,
 creating variations in how full each page is.
For queries that scan portions of the indexes of a table, fragmentation can cause additional page reads.
This values should be as close to zero as possible, but values from 0 – 10% may be acceptable.
*/

DECLARE @db_id SMALLINT;
SET @db_id = DB_ID(N'master');
BEGIN
If exists (
SELECT IPS.avg_fragmentation_in_percent as [Fragmentation (%)], 
   object_name(IPS.object_id) AS [TableName with fragmentation],
   SI.name AS [IndexName], 
   IPS.Index_type_desc, 
   IPS.avg_fragment_size_in_pages, 
   IPS.avg_page_space_used_in_percent, 
   IPS.record_count, 
   IPS.ghost_record_count,
   IPS.fragment_count
FROM sys.dm_db_index_physical_stats(@db_id, NULL, NULL, NULL , 'DETAILED') IPS
   JOIN sys.tables ST WITH (nolock) ON IPS.object_id = ST.object_id
   JOIN sys.indexes SI WITH (nolock) ON IPS.object_id = SI.object_id AND IPS.index_id = SI.index_id
WHERE IPS.avg_fragmentation_in_percent > 0
)
begin
SELECT IPS.avg_fragmentation_in_percent as [Fragmentation (%)], 
   object_name(IPS.object_id) AS [TableName with fragmentation],
   SI.name AS [IndexName], 
   IPS.Index_type_desc, 
   IPS.avg_fragment_size_in_pages, 
   IPS.avg_page_space_used_in_percent, 
   IPS.record_count, 
   IPS.ghost_record_count,
   IPS.fragment_count
FROM sys.dm_db_index_physical_stats(@db_id, NULL, NULL, NULL , 'DETAILED') IPS
   JOIN sys.tables ST WITH (nolock) ON IPS.object_id = ST.object_id
   JOIN sys.indexes SI WITH (nolock) ON IPS.object_id = SI.object_id AND IPS.index_id = SI.index_id
WHERE IPS.avg_fragmentation_in_percent > 0
ORDER BY 1 desc
end
else
select '0'
end