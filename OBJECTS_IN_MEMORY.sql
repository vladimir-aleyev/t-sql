SELECT
	wt.session_id,
	wt.wait_type,
	wt.wait_duration_ms,
	s.name AS schema_name,
	o.name AS object_name,
	i.name AS index_name
FROM
	sys.dm_os_buffer_descriptors bd		--DMV Returns information about all the data pages that are currently in the SQL Server buffer pool--
	JOIN (
		SELECT
			*,
			CHARINDEX(':', resource_description) AS file_index,
			CHARINDEX(':', resource_description,
			CHARINDEX(':', resource_description)) AS page_index,
			resource_description AS rd
		FROM
			sys.dm_os_waiting_tasks wt
		WHERE
			wait_type LIKE 'PAGELATCH%'
		) AS wt
	ON bd.database_id = SUBSTRING(wt.rd, 0, wt.file_index)
AND
bd.file_id = SUBSTRING(wt.rd, wt.file_index, wt.page_index)
AND
bd.page_id = SUBSTRING(wt.rd, wt.page_index, LEN(wt.rd))
JOIN 
	sys.allocation_units au ON bd.allocation_unit_id = au.allocation_unit_id
JOIN
	sys.partitions p ON au.container_id = p.partition_id
JOIN
	sys.indexes i ON p.index_id = i.index_id AND p.object_id = i.object_id
JOIN
	sys.objects o ON i.object_id = o.object_id
JOIN
	sys.schemas s ON o.schema_id = s.schema_id

----------------------------------------------------------------------------
------  count of pages loaded for each object in the current database ------
----------------------------------------------------------------------------
SELECT COUNT(*)AS cached_pages_count   
    ,name ,index_id   
FROM sys.dm_os_buffer_descriptors AS bd   
    INNER JOIN   
    (  
        SELECT object_name(object_id) AS name   
            ,index_id ,allocation_unit_id  
        FROM sys.allocation_units AS au  
            INNER JOIN sys.partitions AS p   
                ON au.container_id = p.hobt_id   
                    AND (au.type = 1 OR au.type = 3)  
        UNION ALL  
        SELECT object_name(object_id) AS name     
            ,index_id, allocation_unit_id  
        FROM sys.allocation_units AS au  
            INNER JOIN sys.partitions AS p   
                ON au.container_id = p.partition_id   
                    AND au.type = 2  
    ) AS obj   
        ON bd.allocation_unit_id = obj.allocation_unit_id  
WHERE database_id = DB_ID()  
GROUP BY name, index_id   
ORDER BY cached_pages_count DESC;

----------------------------------------------------------
------- count of pages loaded for each database ----------
----------------------------------------------------------
SELECT COUNT(*)AS cached_pages_count  
    ,CASE database_id   
        WHEN 32767 THEN 'ResourceDb'   
        ELSE db_name(database_id)   
        END AS database_name  
FROM sys.dm_os_buffer_descriptors  
GROUP BY DB_NAME(database_id) ,database_id  
ORDER BY cached_pages_count DESC; 
----------------------------------------------------------

