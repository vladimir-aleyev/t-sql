-------------------------------
--frequently recompiled queries
-------------------------------
SELECT TOP 1000
    qs.plan_generation_num,
    qs.execution_count,
    qs.statement_start_offset,
    qs.statement_end_offset,
    st.text,
	---
						-- Text of the SQL query. 
	CASE
		WHEN qs.statement_start_offset > 0 THEN SUBSTRING(st.text, ((qs.statement_start_offset/2) + 1), (
																					CASE
																						WHEN qs.statement_end_offset = -1 THEN 2147483647
																						ELSE ((qs.statement_end_offset - qs.statement_start_offset)/2) + 1
																					END
																				)
												)
		ELSE RTRIM(LTRIM(st.text))
	END AS sql_text
	---
    FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
    WHERE qs.plan_generation_num > 1
    ORDER BY qs.plan_generation_num DESC

------

SELECT 
	--TOP 1000
    qs.*,
	st.*
FROM
	sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE
	qs.execution_count = 1
	AND
	qs.last_execution_time < '2018-04-11 00:00:00.000'
ORDER BY
	qs.creation_time DESC

--------

SELECT TOP 5 
	query_stats.query_hash AS "Query Hash",   
    SUM(query_stats.total_worker_time) / SUM(query_stats.execution_count) AS "Avg CPU Time",  
    MIN(query_stats.statement_text) AS "Statement Text" 
FROM   
    (	SELECT
			QS.*,   
			SUBSTRING(ST.text, (QS.statement_start_offset/2) + 1,  ((CASE statement_end_offset WHEN -1 THEN DATALENGTH(ST.text)  
																		ELSE QS.statement_end_offset END   - QS.statement_start_offset)/2) + 1) AS statement_text  

		FROM
			sys.dm_exec_query_stats AS QS
CROSS APPLY
	sys.dm_exec_sql_text(QS.sql_handle) as ST) as query_stats  

GROUP BY query_stats.query_hash  
ORDER BY 2 DESC; 


----------------------
--what's being cached:
----------------------
select
    db_name(st.dbid) as database_name,
    cp.bucketid,
    cp.usecounts,
    cp.size_in_bytes,
    cp.objtype,
	cp.*,
    st.text
from sys.dm_exec_cached_plans cp
cross apply sys.dm_exec_sql_text(cp.plan_handle) st
WHERE
	cp.usecounts = 1

--------------------------------------
-- get all single-use plans (a count):
--------------------------------------
;with PlanCacheCte as 
(
    select
        db_name(st.dbid) as database_name,
        cp.bucketid,
        cp.usecounts,
        cp.size_in_bytes,
        cp.objtype,
        st.text
    from sys.dm_exec_cached_plans cp
    cross apply sys.dm_exec_sql_text(cp.plan_handle) st
)
select count(*)
from PlanCacheCte
where usecounts = 1

---------------------------------------------------------------------------------------
--To get a ratio of how many single-use count plans you have compared to all cached plans
---------------------------------------------------------------------------------------
declare @single_use_counts int, @multi_use_counts int

;with PlanCacheCte as 
(
    select
        db_name(st.dbid) as database_name,
        cp.bucketid,
        cp.usecounts,
        cp.size_in_bytes,
        cp.objtype,
        st.text
    from sys.dm_exec_cached_plans cp
    cross apply sys.dm_exec_sql_text(cp.plan_handle) st
    where cp.cacheobjtype = 'Compiled Plan'
)
select @single_use_counts = count(*)
from PlanCacheCte
where usecounts = 1

;with PlanCacheCte as 
(
    select
        db_name(st.dbid) as database_name,
        cp.bucketid,
        cp.usecounts,
        cp.size_in_bytes,
        cp.objtype,
        st.text
    from sys.dm_exec_cached_plans cp
    cross apply sys.dm_exec_sql_text(cp.plan_handle) st
    where cp.cacheobjtype = 'Compiled Plan'
)
select @multi_use_counts = count(*)
from PlanCacheCte
where usecounts > 1

select
    @single_use_counts as single_use_counts,
    @multi_use_counts as multi_use_counts,
    @single_use_counts * 1.0 / (@single_use_counts + @multi_use_counts) * 100
        as percent_single_use_counts


