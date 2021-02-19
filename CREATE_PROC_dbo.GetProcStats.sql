CREATE PROCEDURE dbo.GetProcStats (@order varchar(100) = 'use')
AS
BEGIN
WITH GetQueryStats
(
	plan_handle,
	total_elapsed_time,
	total_logical_reads,
	total_logical_writes,
	total_physical_reads
)
AS
(
SELECT
	qs.plan_handle,
	SUM(qs.total_elapsed_time) AS total_elapsed_time,
	SUM(qs.total_logical_reads) AS total_logical_reads,
	SUM(qs.total_logical_writes) AS total_logical_writes,
	SUM(qs.total_physical_reads) AS total_physical_reads
FROM 
	sys.dm_exec_query_stats qs
GROUP BY
	qs.plan_handle
)

SELECT
	DB_NAME(st.dbid) AS database_name,
	OBJECT_SCHEMA_NAME(st.objectid, st.dbid) AS schema_name,
	OBJECT_NAME(st.objectid, st.dbid) AS proc_name,
	SUM(cp.usecounts) AS use_counts,
	SUM(cp.size_in_bytes) AS size_in_bytes,
	SUM(qs.total_elapsed_time) AS total_elapsed_time,
	CAST( SUM(qs.total_elapsed_time) AS decimal(38, 4) ) / SUM(cp.usecounts) AS avg_elapsed_time_per_use,
	SUM(qs.total_logical_reads) AS total_logical_reads,
	CAST( SUM(qs.total_logical_reads) AS decimal(38, 4) ) / SUM(cp.usecounts) AS avg_logical_reads_per_use,
	SUM(qs.total_logical_writes) AS total_logical_writes,
	CAST( SUM(qs.total_logical_writes) AS decimal(38, 4) ) / SUM(cp.usecounts) AS avg_logical_writes_per_use,
	SUM(qs.total_physical_reads) AS total_physical_reads,
	CAST( SUM(qs.total_physical_reads) AS decimal(38, 4) ) / SUM(cp.usecounts) AS avg_physical_reads_per_use,
	st.text
FROM
	sys.dm_exec_cached_plans cp
CROSS APPLY
	sys.dm_exec_sql_text(cp.plan_handle) st
INNER JOIN
	GetQueryStats qs
	ON cp.plan_handle = qs.plan_handle
INNER JOIN
	sys.procedures p
	ON st.objectid = p.object_id
WHERE
	p.type IN ('P', 'PC')
GROUP BY
	st.dbid, st.objectid, st.text
ORDER BY
	CASE @order
		WHEN 'name' THEN OBJECT_NAME(st.objectid)
		WHEN 'size' THEN SUM(cp.size_in_bytes)
		WHEN 'read' THEN SUM(qs.total_logical_reads)
		WHEN 'write' THEN SUM(qs.total_logical_writes)
		ELSE SUM(cp.usecounts)
	END DESC;
END;
GO

