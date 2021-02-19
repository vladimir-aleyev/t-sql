WITH XMLNAMESPACES('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
SELECT  st.text,
        qp.query_plan
FROM    (
    SELECT  TOP 50 *
    FROM    sys.dm_exec_query_stats
    ORDER BY total_worker_time DESC
) AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
CROSS APPLY qp.query_plan.nodes('//p:RelOp/p:Warnings[(@NoJoinPredicate[.="1"])]') AS q(n) ;