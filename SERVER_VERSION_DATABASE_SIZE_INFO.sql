IF LEFT(CAST(SERVERPROPERTY('ProductVersion') As Varchar),1)<>'8'
BEGIN


DECLARE @tcp_port INT
DECLARE @NumberOfLogicalCPUs INT
DECLARE @TotalRAMInGB INT
DECLARE @ver INT


CREATE TABLE #SERVER_INFO
	(
		ServerName VARCHAR(255),
		DatabaseName VARCHAR(255),
		DataFileSizeMB INT,
		LogFileSizeMB INT,
		TotalDBSizeMB INT
	)

CREATE TABLE #SERVER_INFO2
	(	[Index] INT,
		[Name] VARCHAR(30),
		[Internal_value] VARCHAR(30),
		[Character_value] VARCHAR(300)
	)

INSERT INTO #SERVER_INFO2 EXEC master..xp_msver
SELECT @NumberOfLogicalCPUs = Internal_value FROM #SERVER_INFO2 WHERE Name = 'ProcessorCount';
SELECT @TotalRAMInGB = Internal_value FROM #SERVER_INFO2 WHERE Name = 'PhysicalMemory';
SELECT @tcp_port = local_tcp_port FROM sys.dm_exec_connections WHERE session_id = @@SPID;

INSERT INTO #SERVER_INFO
SELECT
	@@SERVERNAME AS ServerName,
    DB.name AS DatabaseName,
    --SUM(CASE WHEN type = 0 THEN MF.size * 8 / 1024 ELSE 0 END) AS DataFileSizeMB,
    --SUM(CASE WHEN type = 1 THEN MF.size * 8 / 1024 ELSE 0 END) AS LogFileSizeMB,
    --SUM(MF.size * 8 / 1024) AS TotalDBSizeMB

	SUM(CASE WHEN type = 0 THEN MF.size  / 128 ELSE 0 END) AS DataFileSizeMB,
    SUM(CASE WHEN type = 1 THEN MF.size  / 128 ELSE 0 END) AS LogFileSizeMB,
    SUM(MF.size / 128) AS TotalDBSizeMB

FROM
    sys.master_files MF
JOIN sys.databases DB ON DB.database_id = MF.database_id
GROUP BY DB.name

SELECT
	SI.ServerName,
	SERVERPROPERTY('productversion') AS 'Version',
	SERVERPROPERTY ('productlevel') AS 'SP Level',
	SERVERPROPERTY ('edition') AS 'Edition',
	SERVERPROPERTY ('MachineName') AS 'HostName',
	DB.collation_name AS 'Database Collation',
	@@VERSION AS 'VERSION_FULL',
	@NumberOfLogicalCPUs AS '#CPU',
	@TotalRAMInGB AS 'RAM (MB)', 
	@tcp_port AS Local_TCP_Port,
	SI.DatabaseName,
	SI.DataFileSizeMB,
	SI.LogFileSizeMB,
	SI.TotalDBSizeMB,
	DB.recovery_model_desc
FROM
	#SERVER_INFO SI
INNER JOIN
	sys.databases DB
	ON SI.DatabaseName = DB.name
ORDER BY
	SI.DatabaseName

DROP TABLE #SERVER_INFO
DROP TABLE #SERVER_INFO2

END
ELSE
RAISERROR ('Current MS SQL Server version is not supported...', -- Message text.
           1, -- Severity.
           1 -- State.
           );


--select * from sys.dm_server_services


