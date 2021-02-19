USE [msdb]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[DBA_vProcedureExecInfo] as 
with info as (
SELECT
	procedure_stats.database_id					AS database_id,
	procedure_stats.object_id					AS object_id,
	MIN(procedure_stats.type)					AS type, 
    SUM(procedure_stats.total_worker_time	) /
	SUM(procedure_stats.execution_count)		AS AvgCPU_Time,
	SUM(procedure_stats.execution_count		)	AS ExecutionCount,
	SUM(procedure_stats.total_worker_time	)	AS TotalWorkerTime,
    MIN(procedure_stats.ProcedureText		)	AS ProcedureText,
    MIN(procedure_stats.min_worker_time		)	AS MinWorkerTime,
    MAX(procedure_stats.max_worker_time		)	AS MaxWorkerTime,
	SUM(procedure_stats.total_physical_reads)	AS TotalPhysicalReads,
    MIN(procedure_stats.min_physical_reads	)	AS MinPhysicalReads,
    MAX(procedure_stats.max_physical_reads	)	AS MaxPhysicalReads,
	SUM(procedure_stats.total_physical_reads) / 
	SUM(procedure_stats.execution_count)		AS AvgPhysicalReads,
	SUM(procedure_stats.total_logical_writes)	AS TotalLogicalWrites,
    MIN(procedure_stats.min_logical_writes	)	AS MinLogicalWrites,
    MAX(procedure_stats.max_logical_writes	)	AS MaxLogicalWrites,
	SUM(procedure_stats.total_logical_writes) / 
	SUM(procedure_stats.execution_count)		AS AvgLogicalWrites,
	SUM(procedure_stats.total_logical_reads )	AS TotalLogicalReads,
    MIN(procedure_stats.min_logical_reads	)	AS MinLogicalReads,
    MAX(procedure_stats.max_logical_reads	)	AS MaxLogicalReads,
	SUM(procedure_stats.total_logical_reads ) / 
	SUM(procedure_stats.execution_count)		AS AvgLogicalReads,
	SUM(procedure_stats.total_elapsed_time	)	AS TotalElapsedTime,
    MIN(procedure_stats.min_elapsed_time	)	AS MinElapsedTime,
    MAX(procedure_stats.max_elapsed_time	)	AS MaxElapsedTime,
	SUM(procedure_stats.total_elapsed_time	) / 
	SUM(procedure_stats.execution_count)		AS AvgElapsedTime,
 	MIN(procedure_stats.cached_time		)	AS MinCachedTime,
	MAX(procedure_stats.last_execution_time	)	AS LastExecuteTime
FROM 
    (SELECT QS.database_id
			,QS.object_id
			,QS.type
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
			,QS.cached_time		
			,QS.last_execution_time
			,ST.text as Proceduretext
     FROM sys.dm_exec_Procedure_stats AS QS
     CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) as ST) as procedure_stats
WHERE execution_count > 1
and last_execution_time >= dateadd(hour,-3,getdate())
GROUP BY database_id,object_id)
SELECT 
	database_id,
	object_id,
	type, 
	AvgCPU_Time,
	ExecutionCount,
	TotalWorkerTime,
	ProcedureText,
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
	MinCachedTime,
	LastExecuteTime
FROM info

GO