CREATE EVENT SESSION [CacheMisses] ON SERVER 
ADD EVENT sqlserver.sp_cache_miss(SET collect_cached_text=(1),collect_object_name=(1)
    ACTION(sqlserver.plan_handle)
    WHERE ([database_name]=N'Citi_Sales' AND [sqlserver].[is_system]=(0)))
ADD TARGET package0.event_file(SET filename=N'C:\Program Files\Microsoft SQL Server\MSSQL13.NAV2017\MSSQL\Log\cache_miss')
WITH 
(MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_MULTIPLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,
TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

ALTER EVENT SESSION [CacheMisses] ON SERVER STATE = START
 
WAITFOR DELAY '00:01:30.000'
 
ALTER EVENT SESSION [CacheMisses] ON SERVER STATE = STOP 
 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 
CREATE TABLE [#WaitsGather]
 (
 [ID] INT IDENTITY(1, 1) NOT NULL PRIMARY KEY CLUSTERED,
 [WaitsXML] XML 
 );
 
INSERT [#WaitsGather]
 ( [WaitsXML] )
SELECT CONVERT(XML, [event_data]) AS [TargetData]
FROM [sys].[fn_xe_file_target_read_file]( 'C:\Program Files\Microsoft SQL Server\MSSQL13.NAV2017\MSSQL\Log\cache_miss*.xel', NULL, NULL, NULL)
 
;WITH XMLNAMESPACES 
('http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p)
, xe AS (
SELECT 
 [evts].[WaitsXML].[value]('(/event/@name)[1]', 'VARCHAR(100)') as EventName,
 [evts].[WaitsXML].[value]('(/event/@timestamp)[1]', 'DATETIMEOFFSET(7)') as EventTime,
 [evts].[WaitsXML].[value]('(event/data[@name="database_id"]/value)[1]','INT') AS [DatabaseID] ,
 [evts].[WaitsXML].[value]('(event/data[@name ="object_id"]/value)[1]', 'INT') AS [ObjectID] ,
 [evts].[WaitsXML].[value]('(event/data[@name="object_type"]/text)[1]','VARCHAR(100)') AS [ObjectType] ,
 [evts].[WaitsXML].[value]('(event/data[@name ="cached_text"]/value)[1]', 'VARCHAR(8000)') AS [Cached_Text] ,
 [evts].[WaitsXML].[value]('xs:hexBinary((event/action[@name="plan_handle"]/value)[1])', 'VARBINARY(64)') AS [PlanHandle]
FROM [#WaitsGather] AS [evts]
)
SELECT xe.EventName,
 xe.EventTime,
 DB_NAME(xe.DatabaseID) AS [DatabaseName],
 OBJECT_NAME(xe.ObjectID) AS [ObjectName],
 xe.ObjectType,
 xe.Cached_Text,
 deqp.query_plan,
 CompileTime = qpn.ss.value('sum(//p:QueryPlan/@CompileTime)', 'float') ,
 CompileCPU = qpn.ss.value('sum(//p:QueryPlan/@CompileCPU)', 'float') ,
 CompileMemory = qpn.ss.value('sum(//p:QueryPlan/@CompileMemory)', 'float')
FROM xe
 OUTER APPLY sys.dm_exec_query_plan(xe.PlanHandle) AS deqp
 OUTER APPLY deqp.query_plan.nodes('//p:ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS qpn(ss)
ORDER BY xe.EventTime
 
DROP TABLE #WaitsGather