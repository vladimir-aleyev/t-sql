SET NOCOUNT ON;
 
DECLARE @frag float;
DECLARE @dbname nvarchar(130);
DECLARE @dbid int;
 

-- Conditionally select tables and indexes from the sys.dm_db_index_physical_stats function 
-- and convert object and index IDs to names.
SET @dbname = N'work'	-- change the name of the target database here
SET @frag = 10.0        -- change this value to adjust the threshold for fragmentation
 

SELECT @dbid = dbid FROM sys.sysdatabases WHERE name = @dbname
 

SELECT
    PS.object_id AS Objectid,
      O.name AS ObjectName,
      S.name AS SchemaName,
      I.name AS IndexName,
    PS.index_id AS IndexId,
    PS.partition_number AS PartitionNum,
    ROUND(PS.avg_fragmentation_in_percent, 2) AS Fragmentation,
      PS.record_count AS RecordCount
FROM sys.dm_db_index_physical_stats (@dbid, NULL, NULL , NULL, 'SAMPLED') PS
      JOIN sys.objects O ON PS.object_id = O.object_id
      JOIN sys.schemas S ON S.schema_id = O.schema_id
      JOIN sys.indexes I ON I.object_id = PS.object_id
            AND I.index_id = PS.index_id
WHERE PS.avg_fragmentation_in_percent > @frag AND PS.index_id > 0
ORDER BY record_count desc;
