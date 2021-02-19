--Refer:
--https://www.brentozar.com/archive/2016/09/what-to-do-if-sp_blitzfirst-warns-about-high-compilations/
--
--CREATE EVENT SESSION [Showplan] ON SERVER 
--ADD EVENT sqlserver.query_pre_execution_showplan(SET collect_database_name=(1))
--ADD TARGET package0.event_file(SET filename=N'Showplan.xel',max_file_size=(100))
--WITH (MAX_MEMORY=4096 KB,
--EVENT_RETENTION_MODE=ALLOW_MULTIPLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,
--MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
--GO
--2--
/*
CREATE EVENT SESSION [Show_c_plan] ON SERVER 
ADD EVENT sqlserver.query_post_compilation_showplan(SET collect_database_name=(1))
ADD TARGET package0.event_file(SET filename=N'Show_c_plan.xel',max_file_size=(100))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_MULTIPLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,
MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO
*/
--

 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 
CREATE TABLE [#WaitsGather]
       (
         [ID] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY CLUSTERED,
         [WaitsXML] XML 
       );
 
INSERT  [#WaitsGather]
        ( [WaitsXML] )
SELECT    CONVERT(XML, [event_data]) AS [TargetData]
FROM      [sys].[fn_xe_file_target_read_file]( 'C:\Program Files\Microsoft SQL Server\MSSQL13.NAV2017\MSSQL\Log\Show_c_plan*.xel', NULL, NULL, NULL)
 

--SELECT * FROM [#WaitsGather]

--;WITH XMLNAMESPACES 
--('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
--, xe AS (
--SELECT	 
--         [evts].[WaitsXML].[value]('(/event/@name)[1]', 'VARCHAR(100)') AS [EventName],
--         [evts].[WaitsXML].[value]('(/event/@timestamp)[1]', 'DATETIMEOFFSET(7)') AS [EventTime],
--         [evts].[WaitsXML].[value]('(event/data[@name="database_name"]/value)[1]','VARCHAR(128)') AS [DatabaseName] ,
--         [evts].[WaitsXML].[value]('(event/data[@name ="object_id"]/value)[1]', 'INT') AS [ObjectID] ,
--         [evts].[WaitsXML].[value]('(event/data[@name="object_type"]/text)[1]','VARCHAR(100)') AS [ObjectType] ,
--         [evts].[WaitsXML].[value]('(event/data[@name ="object_name"]/value)[1]', 'VARCHAR(8000)') AS [ObjectName] ,
--         [evts].[WaitsXML].[query]('.') AS [QueryPlan],
--         [evts].[WaitsXML].[value]('(event/data[@name ="requested_memory_kb"]/value)[1]', 'BIGINT') AS [CPU_Time],
--         [evts].[WaitsXML].[value]('(event/data[@name ="dop"]/value)[1]', 'BIGINT') AS [DOP],
--         [evts].[WaitsXML].[value]('(event/data[@name ="ideal_memory_kb"]/value)[1]', 'BIGINT') AS [RecompileCount],
--         [evts].[WaitsXML].[value]('(event/data[@name ="granted_memory_kb"]/value)[1]', 'BIGINT') AS [Duration],
--         [evts].[WaitsXML].[value]('(event/data[@name ="estimated_rows"]/value)[1]', 'BIGINT') AS [EstimatedRows],
--         [evts].[WaitsXML].[value]('(event/data[@name ="estimated_cost"]/value)[1]', 'BIGINT') AS [EstimatedCost],
--         [evts].[WaitsXML].[value]('(event/data[@name ="serial_ideal_memory_kb"]/value)[1]', 'BIGINT') AS [SerialIdealMemoryKB]
--FROM     [#WaitsGather] AS [evts]
--CROSS APPLY [evts].[WaitsXML].[nodes](N'/event/data[@name="showplan_xml"]/value/*') AS x(query_plan)
--)
--SELECT xe.*,
--     CompileTime = qpn2.ss.value('sum(//p:QueryPlan/@CompileTime)', 'float') ,
--     CompileCPU = qpn2.ss.value('sum(//p:QueryPlan/@CompileCPU)', 'float') ,
--     CompileMemory = qpn2.ss.value('sum(//p:QueryPlan/@CompileMemory)', 'float')
--FROM xe
--  OUTER APPLY xe.QueryPlan.nodes('//p:ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS qpn2(ss)
--ORDER BY xe.EventTime
 
--DROP TABLE IF EXISTS #WaitsGather;

--2--
SELECT * FROM [#WaitsGather]

;WITH XMLNAMESPACES 
('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
, xe AS (
SELECT	 
         [evts].[WaitsXML].[value]('(/event/@name)[1]', 'VARCHAR(100)') AS [EventName],
         [evts].[WaitsXML].[value]('(/event/@timestamp)[1]', 'DATETIMEOFFSET(7)') AS [EventTime],
         [evts].[WaitsXML].[value]('(event/data[@name="database_name"]/value)[1]','VARCHAR(128)') AS [DatabaseName] ,
         [evts].[WaitsXML].[value]('(event/data[@name ="object_id"]/value)[1]', 'INT') AS [ObjectID] ,
         [evts].[WaitsXML].[value]('(event/data[@name="object_type"]/text)[1]','VARCHAR(100)') AS [ObjectType] ,
         [evts].[WaitsXML].[value]('(event/data[@name ="object_name"]/value)[1]', 'VARCHAR(8000)') AS [ObjectName] ,
         [evts].[WaitsXML].[query]('.') AS [QueryPlan],
         [evts].[WaitsXML].[value]('(event/data[@name ="cpu_time"]/value)[1]', 'BIGINT') AS [CPU_Time],
         --[evts].[WaitsXML].[value]('(event/data[@name ="dop"]/value)[1]', 'BIGINT') AS [DOP],
         [evts].[WaitsXML].[value]('(event/data[@name ="recompile_count"]/value)[1]', 'BIGINT') AS [RecompileCount],
         [evts].[WaitsXML].[value]('(event/data[@name ="duration"]/value)[1]', 'BIGINT') AS [Duration],
         [evts].[WaitsXML].[value]('(event/data[@name ="estimated_rows"]/value)[1]', 'BIGINT') AS [EstimatedRows],
         [evts].[WaitsXML].[value]('(event/data[@name ="estimated_cost"]/value)[1]', 'BIGINT') AS [EstimatedCost],
         [evts].[WaitsXML].[value]('(event/data[@name ="serial_ideal_memory_kb"]/value)[1]', 'BIGINT') AS [SerialIdealMemoryKB]
FROM     [#WaitsGather] AS [evts]
CROSS APPLY [evts].[WaitsXML].[nodes](N'/event/data[@name="showplan_xml"]/value/*') AS x(query_plan)
)
SELECT xe.*,
     CompileTime = qpn2.ss.value('sum(//p:QueryPlan/@CompileTime)', 'float') ,
     CompileCPU = qpn2.ss.value('sum(//p:QueryPlan/@CompileCPU)', 'float') ,
     CompileMemory = qpn2.ss.value('sum(//p:QueryPlan/@CompileMemory)', 'float')
FROM xe
  OUTER APPLY xe.QueryPlan.nodes('//p:ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS qpn2(ss)
ORDER BY xe.EventTime
 
DROP TABLE IF EXISTS #WaitsGather;