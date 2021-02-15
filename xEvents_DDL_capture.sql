--INSERT INTO msdb.dbo.xEvents_ddl (module_guid,package_guid,[object_name],event_data,[file_name],file_offset) 
--SELECT module_guid,package_guid,object_name,CAST(event_Data AS xml),file_name,file_offset 
--FROM sys.fn_xe_file_target_read_file('I:\xevents_logs\ddl_xevents\ddl_xevents_*.xel', NULL, NULL, NULL)

SELECT 
	module_guid,
	package_guid,
	object_name,
	CAST(event_Data AS xml) AS event_Data,
	file_name,file_offset 
FROM
	sys.fn_xe_file_target_read_file('I:\xevents_logs\ddl_xevents\ddl_xevents_*.xel', NULL, NULL, NULL)

--CREATE TABLE msdb.dbo.xEvents_ddl
--(
--module_guid	uniqueidentifier NOT NULL,
--package_guid	uniqueidentifier NOT NULL,
--object_name	nvarchar(256) NOT NULL,
--event_data	xml NOT NULL,
--file_name	nvarchar(260) NOT NULL,
--file_offset	bigint NOT NULL
----timestamp_utc	datetime2 --Applies to: SQL Server 2017 (14.x) and later and Azure SQL Database
--)

--SELECT * FROM msdb.dbo.xEvents_ddl



SELECT 
n.value('(@name)[1]', 'varchar(50)') as event_name,
    n.value('(@package)[1]', 'varchar(50)') AS package_name,
    n.value('(@timestamp)[1]', 'datetime2') AS [utc_timestamp],
--	n.value('(data[@name="database_id"]/value)[1]', 'int') as database_id,
--	n.value('(data[@name="object_id"]/value)[1]', 'int') as object_id,
	n.value('(data[@name="object_type"]/value)[1]', 'int') as object_type,
--	n.value('(data[@name="index_id"]/value)[1]', 'int') as index_id,
--	n.value('(data[@name="related_object_id"]/value)[1]', 'int') as related_object_id,
	n.value('(data[@name="ddl_phase"]/text)[1]', 'varchar(50)') as ddl_phase,	
--	n.value('(data[@name="transaction_id"]/value)[1]', 'bigint') as transaction_id,
	n.value('(data[@name="object_name"]/value)[1]', 'varchar(50)') as object_name,
	n.value('(action[@name="username"]/value)[1]', 'nvarchar(50)') as username,
	n.value('(action[@name="sql_text"]/value)[1]', 'nvarchar(max)') as sql_text,
	n.value('(action[@name="session_id"]/value)[1]', 'int') as session_id,
	n.value('(action[@name="server_principal_name"]/value)[1]', 'nvarchar(50)') as server_principal_name,
	n.value('(action[@name="server_instance_name"]/value)[1]', 'nvarchar(50)') as server_instance_name,
	n.value('(action[@name="is_system"]/value)[1]', 'nvarchar(50)') as is_system,
	n.value('(action[@name="database_name"]/value)[1]', 'nvarchar(128)') as database_name,
	n.value('(action[@name="database_id"]/value)[1]', 'int') as database_id,
	n.value('(action[@name="client_pid"]/value)[1]', 'int') as client_pid,
	n.value('(action[@name="client_hostname"]/value)[1]', 'nvarchar(128)') as client_hostname,
	n.value('(action[@name="client_app_name"]/value)[1]', 'nvarchar(128)') as client_app_name,
	n.value('(action[@name="collect_system_time"]/value)[1]', 'datetime2') as collect_system_time,
	n.value('(data[@name="duration"]/value)[1]', 'int') as duration
FROM 
	msdb.dbo.xEvents_ddl AS ed
cross apply 
	ed.event_data.nodes('event') as q(n)

ORDER BY
	n.value('(data[@name="object_name"]/value)[1]', 'varchar(50)'),
	n.value('(action[@name="collect_system_time"]/value)[1]', 'datetime2')