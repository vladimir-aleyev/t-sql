--- 
USE [msdb]
GO
CREATE TABLE DBA_DBFilesSizeInfo
(
Id BIGINT IDENTITY(1,1) PRIMARY KEY CLUSTERED, 
PostTime SMALLDATETIME,
ServerName VARCHAR(100),
DatabaseName VARCHAR(100),
FileSizeMB INT,
LogicalFileName sysname,
Status sysname,
FreeSpaceMB INT,
FreeSpacePct VARCHAR(7),
)
GO

CREATE PROCEDURE sp_DBA_CollectDBFilesSize
AS
SET NOCOUNT ON;
BEGIN
DECLARE @command VARCHAR(5000)

SELECT @command = 'Use [' + '?' + '] SELECT
CAST(GETDATE() AS SMALLDATETIME) AS PostTime,
@@servername as ServerName,
' + '''' + '?' + '''' + ' AS DatabaseName,
CAST(sysfiles.size/128.0 AS int) AS FileSize,
sysfiles.name AS LogicalFileName,
CONVERT(sysname,DatabasePropertyEx(''?'',''Status'')) AS Status,
CAST(sysfiles.size/128.0 - CAST(FILEPROPERTY(sysfiles.name, ' + '''' +
'SpaceUsed' + '''' + ' ) AS int)/128.0 AS int) AS FreeSpaceMB,
CAST(100 * (CAST (((sysfiles.size/128.0 -CAST(FILEPROPERTY(sysfiles.name,
' + '''' + 'SpaceUsed' + '''' + ' ) AS int)/128.0)/(sysfiles.size/128.0))
AS decimal(4,2))) AS varchar(8)) + ' + '''' + '''' + ' AS FreeSpacePct
FROM dbo.sysfiles'

INSERT INTO 
	msdb.dbo.DBA_DBFilesSizeInfo
		(
		PostTime,
		ServerName,
		DatabaseName,
		FileSizeMB,
		LogicalFileName,
		Status,
		FreeSpaceMB,
		FreeSpacePct
		)
EXEC sp_MSForEachDB @command

END
--------------

CREATE TABLE DBA_DiskSizeInfo (
Id BIGINT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
PostTime SMALLDATETIME,
Drive VARCHAR(20) null,
[MBfree] DECIMAL(20,2),
[MBTotalSize] DECIMAL(20,2),
[VolumeName] VARCHAR(64)
)
GO


CREATE PROCEDURE sp_DBA_CollectDiskSize
AS
SET NOCOUNT ON;
BEGIN

CREATE TABLE #DrvLetter (
Drive VARCHAR(500),
)


INSERT INTO #DrvLetter
EXEC xp_cmdshell 'wmic volume where drivetype="3" get caption, freespace, capacity, label'
DELETE
FROM #DrvLetter
WHERE drive IS NULL OR len(drive) < 4 OR Drive LIKE '%Capacity%'
OR Drive LIKE '%\\%\Volume%'


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
		-- Remove Total Size
		SET @STRLine = REPLACE(@STRLine, LEFT(@STRLine,CHARINDEX(' ',@STRLine)),'')
		-- Get Drive
		SET @Drive = LEFT(LTRIM(@STRLine),CHARINDEX(' ',LTRIM(@STRLine)))
		SET @STRLine = RTRIM(LTRIM(REPLACE(LTRIM(@STRLine), LEFT(LTRIM(@STRLine),CHARINDEX(' ',LTRIM(@STRLine))),'')))
		SET @Freesize = LEFT(LTRIM(@STRLine),CHARINDEX(' ',LTRIM(@STRLine)))
		SET @STRLine = RTRIM(LTRIM(REPLACE(LTRIM(@STRLine), LEFT(LTRIM(@STRLine),CHARINDEX(' ',LTRIM(@STRLine))),'')))
		SET @VolumeName = @STRLine

		INSERT INTO msdb.dbo.DBA_DiskSizeInfo 
		SELECT CAST(GETDATE() AS SMALLDATETIME), @Drive, @Freesize/1024/1024 , @TotalSize, @VolumeName

		DELETE FROM #DrvLetter  
	END
SET ROWCOUNT 0
DROP TABLE #DrvLetter

END