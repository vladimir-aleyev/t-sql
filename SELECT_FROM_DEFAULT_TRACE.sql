SELECT 
	*
    --TextData,
    --HostName,
    --ApplicationName,
    --LoginName, 
    --StartTime  
FROM 
[fn_trace_gettable]('C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER_01\MSSQL\Log\log_5411.trc', DEFAULT) 
WHERE
--StartTime >= '2018-03-07 16:00:00.000'
--and
--StartTime <= '2018-03-07 17:46:00.000'
--AND
--SPID IN (711,524)
--ORDER BY
--SPID, StartTime

	TextData 
	IS NOT NULL
--	LIKE '%dbcc index%'; ----- Location of default trace will be different ,so kindly check that accordingly


--EXECUTE xp_cmdshell 'DIR "C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER_01\MSSQL\Log"';

--SELECT * FROM sys.traces

