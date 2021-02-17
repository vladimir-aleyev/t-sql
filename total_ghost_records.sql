--Руководство по процессу очистки фантомных записей--
--https://docs.microsoft.com/ru-ru/sql/relational-databases/ghost-record-cleanup-process-guide?view=sql-server-ver15


SELECT sum(ghost_record_count) total_ghost_records, db_name(database_id) 
FROM sys.dm_db_index_physical_stats (NULL, NULL, NULL, NULL, 'SAMPLED')
group by database_id
order by total_ghost_records desc

--Поэтому этот процесс можно отключить с помощью флага трассировки 661. Однако отключение процесса оказывает влияние на производительность.--