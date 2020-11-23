use master
GO

if isnull(object_id('dbo.sp_fixeddrives'),0) = 0
	exec('create procedure dbo.sp_fixeddrives as print ''temporary procedure to hold location so we can use ALTER in the script''')
GO

/* Author : Kun Lee

Change Log
	Kun Lee 20130723 Changed the Ouput to match as close as possible with xp_fixeddrivs
	Kun Lee 20130813 Fix the known bug on Windows 2003 doesn't return Volume name when lenght is longer than x number of charactors
	
-- Make sure xp_cmdshell is turned on
-- You should be able to run WMI scrip via xp_cmdshell

EXAMPLE 
 EXEC sp_fixeddrives - Print out just fixed drive info with free space
 EXEC sp_fixeddrives 1 -- Print out more detail per DB
*/

ALTER PROCEDURE dbo.sp_fixeddrives
	@format tinyint = 0
AS
BEGIN

SET ARITHIGNORE ON
SET NOCOUNT ON

DECLARE @SQL NVARCHAR(1000)

CREATE TABLE #DrvLetter (
    Drive VARCHAR(500),
    )
CREATE TABLE #DrvInfo (
    Drive VARCHAR(500) null,
    [MB free] DECIMAL(20,2),
    [MB TotalSize] DECIMAL(20,2),
    [Volume Name] VARCHAR(64)
    )



INSERT INTO #DrvLetter
EXEC xp_cmdshell 'wmic volume where drivetype="3" get caption, freespace, capacity, label'

DELETE
FROM #DrvLetter
WHERE drive IS NULL OR len(drive) < 4 OR Drive LIKE '%Capacity%'
	OR Drive LIKE  '%\\%\Volume%'


DECLARE @STRLine VARCHAR(8000)
DECLARE @Drive varchar(500)
DECLARE @TotalSize REAL
DECLARE @Freesize REAL
DECLARE @VolumeName VARCHAR(64)

WHILE EXISTS(SELECT 1 FROM #DrvLetter)
BEGIN
SET ROWCOUNT 1
SELECT @STRLine = drive FROM #DrvLetter

-- Get TotalSize
SET @TotalSize= CAST(LEFT(@STRLine,CHARINDEX(' ',@STRLine)) AS REAL)/1024/1024
--SELECT @TotalSize

-- Remove Total Size
SET @STRLine = REPLACE(@STRLine, LEFT(@STRLine,CHARINDEX(' ',@STRLine)),'')
-- Get Drive

SET @Drive = LEFT(LTRIM(@STRLine),CHARINDEX(' ',LTRIM(@STRLine)))
--SELECT @Drive

SET @STRLine = RTRIM(LTRIM(REPLACE(LTRIM(@STRLine), LEFT(LTRIM(@STRLine),CHARINDEX(' ',LTRIM(@STRLine))),'')))

SET @Freesize = LEFT(LTRIM(@STRLine),CHARINDEX(' ',LTRIM(@STRLine)))
--SELECT @Freesize/1024/1024

SET @STRLine = RTRIM(LTRIM(REPLACE(LTRIM(@STRLine), LEFT(LTRIM(@STRLine),CHARINDEX(' ',LTRIM(@STRLine))),'')))
SET @VolumeName = @STRLine
-- 

INSERT INTO #DrvInfo
SELECT @Drive, @Freesize/1024/1024 , @TotalSize, @VolumeName

DELETE FROM #DrvLetter
END

SET ROWCOUNT 0



-- POPULATE TEMP TABLE WITH LOGICAL DISKS
-- This is FIX/Workaround for Windows 2003 bug that WMIC doesn't return volume name that is over X number of charactors.
SET @SQL ='wmic /FailFast:ON logicaldisk where (drivetype ="3" and volumename!="RECOVERY" AND volumename!="System Reserved") get deviceid,volumename  /Format:csv'
if object_id('tempdb..#output1') is not null drop table #output1
CREATE TABLE #output1 (Col1 VARCHAR(2048))
INSERT INTO #output1
EXEC master..xp_cmdshell @SQL
DELETE #output1 where ltrim(col1) is null or len(col1) = 1 or Col1 like 'Node,DeviceID,VolumeName%'


if object_id('tempdb..#logicaldisk') is not null drop table #logicaldisk
CREATE TABLE #logicaldisk (DeviceID varchar(128),VolumeName varchar(256))

DECLARE @NodeName varchar(128)
SET @NodeName = (SELECT TOP 1 LEFT(Col1, CHARINDEX(',',Col1)) FROM #output1)

-- Clean up server name
UPDATE #output1 SET Col1 = REPLACE(Col1, @NodeName, '')

INSERT INTO #logicaldisk
SELECT LEFT(Col1, CHARINDEX(',',Col1)-2),  SUBSTRING(COL1, CHARINDEX(',',Col1)+1, LEN(col1))
FROM #output1


UPDATE dr
SET dr.[Volume Name] = ld.VolumeName
	FROM #DrvInfo dr RIGHT OUTER JOIN #logicaldisk ld ON left(dr.Drive,1) = ld.DeviceID
WHERE LEN([Volume Name]) = 1


IF @format = 0
BEGIN
SELECT CASE
		WHEN LEN(drive) = 3 THEN LEFT(drive,1)
		ELSE drive
	END AS drive,
	[MB free],	[MB TotalSize], [Volume Name]

FROM #DrvInfo
ORDER BY 1
END

ELSE IF @format = 1
BEGIN

	CREATE TABLE #DBInfo2   
	( ServerName VARCHAR(100),  
	DatabaseName VARCHAR(100),  
	FileSizeMB INT,  
	LogicalFileName sysname,  
	PhysicalFileName NVARCHAR(520),  
	Status sysname,  
	Updateability sysname,  
	RecoveryMode sysname,  
	FreeSpaceMB INT,  
	FreeSpacePct VARCHAR(7),  
	FreeSpacePages INT,  
	PollDate datetime)  

	DECLARE @command VARCHAR(5000)  

	SELECT @command = 'Use [' + '?' + '] SELECT  
	@@servername as ServerName,  
	' + '''' + '?' + '''' + ' AS DatabaseName,  
	CAST(sysfiles.size/128.0 AS int) AS FileSize,  
	sysfiles.name AS LogicalFileName, sysfiles.filename AS PhysicalFileName,  
	CONVERT(sysname,DatabasePropertyEx(''?'',''Status'')) AS Status,  
	CONVERT(sysname,DatabasePropertyEx(''?'',''Updateability'')) AS Updateability,  
	CONVERT(sysname,DatabasePropertyEx(''?'',''Recovery'')) AS RecoveryMode,  
	CAST(sysfiles.size/128.0 - CAST(FILEPROPERTY(sysfiles.name, ' + '''' +  
		   'SpaceUsed' + '''' + ' ) AS int)/128.0 AS int) AS FreeSpaceMB,  
	CAST(100 * (CAST (((sysfiles.size/128.0 -CAST(FILEPROPERTY(sysfiles.name,  
	' + '''' + 'SpaceUsed' + '''' + ' ) AS int)/128.0)/(sysfiles.size/128.0))  
	AS decimal(4,2))) AS varchar(8)) + ' + '''' +  '''' + ' AS FreeSpacePct
	FROM dbo.sysfiles'  
	INSERT INTO #DBInfo2  
	   (ServerName,  
	   DatabaseName,  
	   FileSizeMB,  
	   LogicalFileName,  
	   PhysicalFileName,  
	   Status,  
	   Updateability,  
	   RecoveryMode,  
	   FreeSpaceMB,  
	   FreeSpacePct)  
	EXEC sp_MSForEachDB @command  


	SELECT  
	   db.DatabaseName as DBName,  
	   db.LogicalFileName as DBLogicalFileName,  
	   db.PhysicalFileName as DBPhysicalFileName,  
	   db.RecoveryMode as DBRecoveryMode,  
	   db.FileSizeMB AS DBFileSizeMB,     
	   db.FreeSpaceMB as DBFreeSpaceMB,  
	   db.FreeSpacePct as DBFreeSpacePct,
	   CASE
		WHEN LEN(dr.drive) = 3 THEN LEFT(dr.drive,1)
		ELSE dr.drive
	END AS Drive,
	dr.[MB free] as DriveFreeSpaceMB,
	dr.[MB TotalSize] as DriveTotalSizeMB, 
	CAST((dr.[MB free]/dr.[MB TotalSize]) * 100 AS NUMERIC(5,2)) as DriveFreeSpacePct,
	dr.[Volume Name]
	FROM #DBInfo2 db
		JOIN #DrvInfo dr ON LEFT(db.PhysicalFileName,LEN(dr.drive)) =  LEFT(dr.drive,LEN(dr.drive)) 
	WHERE db.DatabaseName not in (
				SELECT DatabaseName
				FROM #DBInfo2 DB
					JOIN (SELECT drive FROM #DrvInfo WHERE LEN(drive) > 3) DR on LEFT(db.PhysicalFileName, LEN(drive)) = DR.drive)
	UNION ALL
	SELECT  
	   db.DatabaseName,  
	   db.LogicalFileName,  
	   db.PhysicalFileName,  
	   db.RecoveryMode,  
	   db.FileSizeMB,     
	   db.FreeSpaceMB as DBFreeSpaceMB,  
	   db.FreeSpacePct as DBFreeSpacePct,
	   CASE
		WHEN LEN(dr.drive) = 3 THEN LEFT(dr.drive,1)
		ELSE dr.drive
	END AS drive,
	dr.[MB free] AS DriveFreeSpaceMB,	dr.[MB TotalSize] as DriveTotalSizeMB, 
	CAST((dr.[MB free]/dr.[MB TotalSize]) * 100 AS NUMERIC(5,2)) as DriveFreeSpacePct, 
	dr.[Volume Name]
	
	FROM #DBInfo2 db
		JOIN #DrvInfo dr ON LEFT(db.PhysicalFileName,LEN(dr.drive)) =  LEFT(dr.drive,LEN(dr.drive))
	WHERE LEN(dr.drive) > 3 
	ORDER BY  
	   db.DatabaseName 

	DROP TABLE #DBInfo2
END

DROP TABLE #logicaldisk
DROP TABLE #DrvLetter
DROP TABLE #DrvInfo

END

go

