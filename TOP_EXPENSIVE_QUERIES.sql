DECLARE @top TINYINT = 10

--INSERT INTO msdb.dbo.DBA_SQL_TopSQL_QueryStat
--(
--Query_hash,
--SQL_Text,
--ExecutionCount,
--TotalLogicalReads,
--LastLogicalReads,
--TotalLogicalWrites,
--LastLogicalWrites,
--TotalWorkerTimeS,
--LastWorkerTimeS,
--TotalElapsedTimeS,
--LastElapsedTimeS,
--MinElapsedTimeS,
--MaxElapsedTimeS,
--LastExecutionTime,
--QueryPlan	
--)

SELECT TOP(@top) 
	qs.query_hash, -- Binary hash value calculated on the query and used to identify queries with similar logic.
	SUBSTRING
	(
	qt.text, (qs.statement_start_offset/2)+1,
				(
					(
					CASE qs.statement_end_offset
					WHEN -1 THEN DATALENGTH(qt.TEXT)
					ELSE qs.statement_end_offset
					END
					- qs.statement_start_offset
					)
					/2
				)
	+1
	) AS SQL_Text,
	qs.execution_count, --Количество выполнений плана с момента последней компиляции.
	qs.total_logical_reads, -- Общее количество операций логического считывания при выполнении плана с момента его компиляции.
	qs.last_logical_reads, -- Количество операций логического считывания за время последнего выполнения плана.
	qs.total_logical_writes, -- Общее количество операций логической записи при выполнении плана с момента его компиляции.
	qs.last_logical_writes, -- Количество операций логической записи за время последнего выполнения плана.
	qs.total_worker_time/1000000 total_worker_time_in_S, -- Общее время ЦП, затраченное на выполнение плана с момента компиляции, в микросекундах (но с точностью до миллисекунды).
	qs.last_worker_time/1000000 last_worker_time_in_S, -- Время ЦП, затраченное на последнее выполнение плана, в микросекундах (но с точностью до миллисекунды). *само время выполнения запроса*
	qs.total_elapsed_time/1000000 total_elapsed_time_in_S, -- Общее время, затраченное на выполнение плана, в микросекундах (но с точностью до миллисекунды).
	qs.last_elapsed_time/1000000 last_elapsed_time_in_S, -- Время, затраченное на последнее выполнение плана, в микросекундах (но с точностью до миллисекунды). *время ожидания или ожидания+last_worker_time*
	qs.min_elapsed_time/1000000 min_elapsed_time_in_S,
	qs.max_elapsed_time/1000000 max_elapsed_time_in_S,
	qs.last_execution_time,
	qs.plan_handle,
	qp.query_plan
FROM
	sys.dm_exec_query_stats qs
	CROSS APPLY
	sys.dm_exec_sql_text(qs.sql_handle) qt
	CROSS APPLY
	sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE
	qs.execution_count > 1
	AND
	qs.last_execution_time >= DATEADD(DD,-1,GETDATE())
	
ORDER BY
--	qs.total_logical_reads DESC -- logical reads
--  qs.total_logical_writes DESC -- logical writes
--  qs.total_worker_time DESC -- CPU time
--qs.last_execution_time DESC,	
  qs.last_worker_time DESC -- CPU time