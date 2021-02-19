DECLARE @ts_now BIGINT

SELECT @ts_now = cpu_ticks/(cpu_ticks/ms_ticks) FROM sys.dm_os_sys_info

SELECT 
	record_id,
	DATEADD(ms,-1 * (@ts_now - [timestamp]), GETDATE()) AS EventTime,
	SQLProcessUtilisation,
	SystemIdle,
	100 - SystemIdle - SQLProcessUtilisation AS OtherProcessUtilisation 
FROM
(SELECT 
	record.value('(./Record/@id)[1]','int') AS record_id,
	record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]','int') AS SystemIdle,
	record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS SQLProcessUtilisation,
	timestamp
FROM
	(SELECT 
		TIMESTAMP, CONVERT(xml, record) AS record
	FROM
		sys.dm_os_ring_buffers
	WHERE
		ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
		AND
		record LIKE '%<SystemHealth>%'
	) AS x
) AS y




