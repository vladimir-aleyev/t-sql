DECLARE @who2 TABLE (
	SPID INT NULL,
	Status VARCHAR(1000) NULL,
	Login SYSNAME NULL,
	HostName SYSNAME NULL,
	BlkBy SYSNAME NULL,
	DBName SYSNAME NULL,
	Command VARCHAR(8000) NULL,
	CPUTime INT NULL,
	DiskIO INT NULL,
	LastBatch VARCHAR(250) NULL,
	ProgramName VARCHAR(250) NULL,
	SPID2 INT NULL, -- a second SPID for some reason...?
	REQUESTID INT NULL
)
INSERT INTO @who2
EXEC sp_who2

SELECT 
	[SPID],
	[Status],
	[Login],
	[HostName],
	[BlkBy],
	[DBName],
	[Command],
	[CPUTime],
	[DiskIO],
	[LastBatch],
	[ProgramName],
	[SPID2],
	[REQUESTID]
FROM 
	@who2 w
ORDER BY
	CPUTime DESC
