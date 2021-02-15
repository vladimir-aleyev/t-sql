CREATE EVENT SESSION [ddl_xevents] ON SERVER 
ADD EVENT sqlserver.alter_table_update_data(
    ACTION(package0.collect_system_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)
    WHERE ([package0].[not_equal_uint64]([sqlserver].[database_id],(2)) AND [package0].[not_equal_uint64]([sqlserver].[database_id],(3)))),
ADD EVENT sqlserver.data_masking_ddl_column_definition(
    ACTION(package0.collect_system_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)
    WHERE ([database_id]<>(2))),
ADD EVENT sqlserver.database_cmptlevel_change,
ADD EVENT sqlserver.database_created(
    ACTION(package0.collect_system_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)),
ADD EVENT sqlserver.database_dropped(
    ACTION(package0.collect_system_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)),
ADD EVENT sqlserver.database_file_size_change,
ADD EVENT sqlserver.ddl_with_wait_at_low_priority(
    ACTION(package0.collect_system_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)
    WHERE ([database_id]<>(2))),
ADD EVENT sqlserver.hadr_ddl_failover_execution_state(
    ACTION(package0.collect_system_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)),
ADD EVENT sqlserver.metadata_ddl_add_column(
    ACTION(package0.collect_system_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)
    WHERE ([database_id]<>(2))),
ADD EVENT sqlserver.metadata_ddl_alter_column(
    ACTION(package0.collect_system_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)
    WHERE ([database_id]<>(2))),
ADD EVENT sqlserver.metadata_ddl_drop_column(
    ACTION(package0.collect_system_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)
    WHERE ([database_id]<>(2))),
ADD EVENT sqlserver.object_altered(
    ACTION(package0.collect_system_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)
    WHERE ([database_id]<>(2))),
ADD EVENT sqlserver.object_created(SET collect_database_name=(0)
    ACTION(package0.collect_system_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)
    WHERE ([package0].[not_equal_uint64]([database_id],(2)) AND [object_type]<>(21587))),
ADD EVENT sqlserver.object_deleted(
    ACTION(package0.collect_system_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.client_pid,sqlserver.database_id,sqlserver.database_name,sqlserver.is_system,sqlserver.nt_username,sqlserver.server_instance_name,sqlserver.server_principal_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)
    WHERE ([database_id]<>(2))),
ADD EVENT sqlserver.server_memory_change,
ADD EVENT sqlserver.trace_flag_changed
ADD TARGET package0.event_file(SET filename=N'I:\xevents_logs\ddl_xevents\ddl_xevents.xel',max_file_size=(10))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO


