------------------------------------------------------------------------------------------------------------------------------
---	usr_obj_kb сколько данных во временной базе данных используется в прикладном коде, например, при создании временных таблиц.
---	internal_obj_kb показывает, сколько данных используется для системных задач
---	version_store_kb показывает объем данных для хранения версий строк при использовании версионности.
------------------------------------------------------------------------------------------------------------------------------

SELECT
	SUM(user_object_reserved_page_count)*8 as usr_obj_kb,
	SUM(internal_object_reserved_page_count)*8 as internal_obj_kb,
	SUM(version_store_reserved_page_count)*8 as version_store_kb,
	SUM(unallocated_extent_page_count)*8 as freespace_kb,
	SUM(mixed_extent_page_count)*8 as mixedextent_kb
FROM
	tempdb.sys.dm_db_file_space_usage


-------------------------------------------------------
-- объем данных во временной базе для каждой сессии.---
-------------------------------------------------------
SELECT es.session_id
, ec.connection_id
, es.login_name
, es.host_name
, st.text
, su.user_objects_alloc_page_count
, su.user_objects_dealloc_page_count
, su.internal_objects_alloc_page_count
, su.internal_objects_dealloc_page_count
, ec.last_read
, ec.last_write
, es.program_name
FROM 
	tempdb.sys.dm_db_session_space_usage su
	INNER JOIN
	sys.dm_exec_sessions es ON su.session_id = es.session_id
	LEFT OUTER JOIN 
	sys.dm_exec_connections ec ON su.session_id = ec.most_recent_session_id
	OUTER APPLY 
	sys.dm_exec_sql_text(ec.most_recent_sql_handle) st


-------------------------------------------------------
SELECT
	files.physical_name, files.name,
	stats.num_of_writes, (1.0 * stats.io_stall_write_ms / stats.num_of_writes) AS avg_write_stall_ms,
	stats.num_of_reads, (1.0 * stats.io_stall_read_ms / stats.num_of_reads) AS avg_read_stall_ms
FROM
	sys.dm_io_virtual_file_stats(2, NULL) as stats
	INNER JOIN 
	master.sys.master_files AS files
	ON stats.database_id = files.database_id
	AND stats.file_id = files.file_id
WHERE
	files.type_desc = 'ROWS'

---------------------------------------------------------


SELECT
	stats.*
FROM
	sys.dm_io_virtual_file_stats(2, NULL) as stats

----------------------------------------------------------------------------------------------------
--- Этим запросом мы пытаемся найти latch на системные страницы PFS, GAM, SGAM в базе данных tempdb.
--- Если запрос ничего не возвращает или возвращает строки только с «Is Not PFS, GAM, or SGAM page»,
--- то скорее всего текущая нагрузка не требует увеличения файлов tempdb.
----------------------------------------------------------------------------------------------------

SELECT
	session_id,
	wait_type,
	wait_duration_ms,
	blocking_session_id,
	resource_description
	--,
	--ResourceType = 
	--				CASE
	--					WHEN Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 1 % 8088 = 0 Then 'Is PFS Page'
	--					WHEN Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 2 % 511232 = 0 Then 'Is GAM Page'
	--					WHEN Cast(Right(resource_description, Len(resource_description) - Charindex(':', resource_description, 3)) As Int) - 3 % 511232 = 0 Then 'Is SGAM Page'
	--					ELSE 'Is Not PFS, GAM, or SGAM page'
	--				END
FROM
	sys.dm_os_waiting_tasks
WHERE
	wait_type Like 'PAGE%LATCH_%'
	AND
	resource_description Like '2:%' 
-------------------------------------------------------------------------------------------------------
