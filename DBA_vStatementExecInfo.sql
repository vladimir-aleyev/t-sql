USE [msdb]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[DBA_vStatementExecInfo] AS 
WITH info AS (
SELECT
	query_stats.query_hash					AS QueryHash, 
    SUM(query_stats.total_worker_time	) /
	SUM(query_stats.execution_count)		AS AvgCPU_Time,
	SUM(query_stats.execution_count		)	AS ExecutionCount,
	SUM(query_stats.total_worker_time	)	AS TotalWorkerTime,
    MIN(query_stats.statement_text		)	AS StatementText,
    MIN(query_stats.min_worker_time		)	AS MinWorkerTime,
    MAX(query_stats.max_worker_time		)	AS MaxWorkerTime,
	SUM(query_stats.total_physical_reads)	AS TotalPhysicalReads,
    MIN(query_stats.min_physical_reads	)	AS MinPhysicalReads,
    MAX(query_stats.max_physical_reads	)	AS MaxPhysicalReads,
	SUM(query_stats.total_physical_reads) / 
	SUM(query_stats.execution_count)		AS AvgPhysicalReads,
	SUM(query_stats.total_logical_writes)	AS TotalLogicalWrites,
    MIN(query_stats.min_logical_writes	)	AS MinLogicalWrites,
    MAX(query_stats.max_logical_writes	)	AS MaxLogicalWrites,
	SUM(query_stats.total_logical_writes) / 
	SUM(query_stats.execution_count)		AS AvgLogicalWrites,
	SUM(query_stats.total_logical_reads )	AS TotalLogicalReads,
    MIN(query_stats.min_logical_reads	)	AS MinLogicalReads,
    MAX(query_stats.max_logical_reads	)	AS MaxLogicalReads,
	SUM(query_stats.total_logical_reads ) / 
	SUM(query_stats.execution_count)		AS AvgLogicalReads,
	SUM(query_stats.total_elapsed_time	)	AS TotalElapsedTime,
    MIN(query_stats.min_elapsed_time	)	AS MinElapsedTime,
    MAX(query_stats.max_elapsed_time	)	AS MaxElapsedTime,
	SUM(query_stats.total_elapsed_time	) / 
	SUM(query_stats.execution_count)		AS AvgElapsedTime,
 	MIN(query_stats.creation_time		)	AS MinCreationTime,
	MAX(query_stats.last_execution_time	)	AS LastExecuteTime
FROM 
    (SELECT QS.query_hash
			,QS.total_worker_time	
			,QS.execution_count			
			,QS.min_worker_time		
			,QS.max_worker_time		
			,QS.min_physical_reads	
			,QS.max_physical_reads	
			,QS.total_physical_reads
			,QS.total_logical_writes
			,QS.min_logical_writes	
			,QS.max_logical_writes	
			,QS.min_logical_reads	
			,QS.max_logical_reads	
			,QS.total_logical_reads 
			,QS.min_elapsed_time	
			,QS.max_elapsed_time	
			,QS.total_elapsed_time	
			,QS.creation_time		
			,QS.last_execution_time
    ,SUBSTRING(ST.text, (QS.statement_start_offset/2) + 1,
    ((CASE statement_end_offset 
        WHEN -1 THEN DATALENGTH(ST.text)
        ELSE QS.statement_end_offset END 
            - QS.statement_start_offset)/2) + 1) AS statement_text
     FROM sys.dm_exec_query_stats AS QS
     CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) AS ST) AS query_stats
WHERE execution_count > 1
and last_execution_time >= dateadd(hour,-3,getdate())
GROUP BY query_stats.query_hash)
SELECT 
	QueryHash, 
	AvgCPU_Time,
	ExecutionCount,
	TotalWorkerTime,
	StatementText,
	MinWorkerTime,
	MaxWorkerTime,
	TotalPhysicalReads,
	MinPhysicalReads,
	MaxPhysicalReads,
	AvgPhysicalReads,
	TotalLogicalWrites,
	MinLogicalWrites,
	MaxLogicalWrites,
	AvgLogicalWrites,
	TotalLogicalReads,
	MinLogicalReads,
	MaxLogicalReads,
	AvgLogicalReads,
	TotalElapsedTime,
	MinElapsedTime,
	MaxElapsedTime,
	AvgElapsedTime,
	MinCreationTime,
	LastExecuteTime
FROM info

GO