SET STATISTICS IO ON;
SET STATISTICS TIME ON;

DECLARE @top TINYINT = 50
INSERT INTO dbo.DBA_SQL_TopProcedureExecStat
(	DBName,
	ObjectName,
	SPText,
	ExecutionCount,
	TotalLogicalReads,
	LastLogicalReads,
	TotalLogicalWrites,
	LastLogicalWrites,
	TotalWorkerTimeS,
	LastWorkerTimeS,
	TotalElapsedTimeS,
	LastElapsedTimeS,
	MinElapsedTimeS,
	MaxElapsedTimeS,
	LastExecutionTime,
	QueryPlan)

SELECT TOP(@top)
	DB_NAME(ps.database_id) AS DBName,
	OBJECT_NAME(ps.object_id,ps.database_id) AS OBJECTName,
	qt.text, 
	ps.execution_count, --Количество выполнений
	ps.total_logical_reads, -- Общее количество операций логического считывания при выполнении плана с момента его компиляции.
	ps.last_logical_reads, -- Количество операций логического считывания за время последнего выполнения плана.
	ps.total_logical_writes, -- Общее количество операций логической записи при выполнении плана с момента его компиляции.
	ps.last_logical_writes, -- Количество операций логической записи за время последнего выполнения плана.
	ps.total_worker_time/1000000 total_worker_time_in_S, -- Общее время ЦП, затраченное на выполнение плана с момента компиляции.
	ps.last_worker_time/1000000 last_worker_time_in_S, -- Время ЦП, затраченное на последнее выполнение плана. *само время выполнения запроса*
	ps.total_elapsed_time/1000000 total_elapsed_time_in_S, -- Общее время, затраченное на выполнение плана.
	ps.last_elapsed_time/1000000 last_elapsed_time_in_S, -- Время, затраченное на последнее выполнение плана. *время ожидания или ожидания+last_worker_time*
	ps.min_elapsed_time/1000000 min_elapsed_time_in_S,
	ps.max_elapsed_time/1000000 max_elapsed_time_in_S,
	ps.last_execution_time,
	qp.query_plan
FROM
	sys.dm_exec_procedure_stats ps
	CROSS APPLY
	sys.dm_exec_sql_text(ps.sql_handle) qt
	CROSS APPLY
	sys.dm_exec_query_plan(ps.plan_handle) qp
WHERE
	ps.execution_count > 1
	AND
	ps.last_execution_time >= DATEADD(DD,-1,GETDATE())
ORDER BY
   ps.last_worker_time DESC

