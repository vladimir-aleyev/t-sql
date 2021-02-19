

/*Количество процессоров и памяти для версий SQL 2005 и 2008*/
SELECT
	@@SERVERNAME AS 'Имя SQL сервера',
	( cpu_count / hyperthread_ratio )AS NumberOfPhysicalCPUs,
	CASE
	WHEN hyperthread_ratio = cpu_count THEN cpu_count
	ELSE ( ( cpu_count - hyperthread_ratio ) / ( cpu_count / hyperthread_ratio ) )
	END AS NumberOfCoresInEachCPU,
	CASE
	WHEN hyperthread_ratio = cpu_count THEN cpu_count
	ELSE ( cpu_count / hyperthread_ratio ) * ( ( cpu_count - hyperthread_ratio ) / ( cpu_count / hyperthread_ratio ) )
	END AS TotalNumberOfCores,
	cpu_count AS NumberOfLogicalCPUs,
	CONVERT(MONEY, Round(physical_memory_in_bytes / 1073741824.0, 0)) AS TotalRAMInGB
FROM
	sys.dm_os_sys_info
