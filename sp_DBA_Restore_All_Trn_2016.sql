USE [msdb]
GO
/****** Object:  StoredProcedure [dbo].[DBA_Restore_All_Trn_2016]    Script Date: 29-Nov-17 12:27:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
CREATE PROCEDURE [dbo].[DBA_Restore_All_Trn_2016]

  /*Restore all database logs from backup log files from specific folder*/

	@backup_log_path  VARCHAR(500) = 'D:\MSSQL\Backup',
	@Input_DatabaseName VARCHAR(128) = 'All',
	@recovery_flag BIT = 0,		-- 0 = NORECOVERY, 1 = RECOVERY
	@update_flag BIT = 1	-- 0 = VIEW NECESSARY RESTORE LOGs, 1 = RESTORE LOG

AS
 SET NOCOUNT ON;
BEGIN

 DECLARE @db_backup_lsn numeric(25,0)
 DECLARE @result int
 DECLARE @id int
 DECLARE @cmd VARCHAR(1000)
 DECLARE @backup_list TABLE ([File] varchar(1000))
 DECLARE @backup_file VARCHAR(100)
 DECLARE @DatabaseName VARCHAR(128)
 DECLARE @data_file_name VARCHAR(128)
 DECLARE @log_file_name VARCHAR(128)
 DECLARE @data_file_path VARCHAR(128)
 DECLARE @log_file_path VARCHAR(128)
 DECLARE @rc1 INT;
 DECLARE @rc2 INT;
 
DROP TABLE IF EXISTS #backup_list_T;
DROP TABLE IF EXISTS #backup_header;

CREATE TABLE #backup_list_T (
	ID int IDENTITY(1,1) PRIMARY KEY CLUSTERED NOT NULL,
	FileName varchar(255),
	DatabaseName varchar(128),
	FirstLSN numeric(25,0),
	LastLSN numeric(25,0),
	BackupDate datetime,
	ForkID uniqueidentifier
)

CREATE TABLE #backup_header
	(
		BackupName varchar(128),
		BackupDescription varchar(256),
		BackupType int, 
		ExpirationDate datetime NULL,
		Compressed int,
		Position int,
		DeviceType int,
		UserName varchar(128),
		ServerName varchar(128),
		DatabaseName varchar(128),
		DatabaseVersion int,
		DatabaseCreationDate datetime,
		BackupSize numeric(20,0) NULL,
		FirstLSN numeric(25,0) NULL,
		LastLSN numeric(25,0) NULL,
		CheckpointLSN numeric(25,0) NULL,
		DatabaseBackupLSN numeric(25,0) NULL,
		BackupStartDate datetime,
		BackupFinishDate datetime,
		SortOrder int,
		CodePage int,
		UnicodeLocaleId int,
		UnicodeComparisonStyle int,
		CompatibilityLevel int,
		SoftwareVendorId int,
		SoftwareVersionMajor int,
		SoftwareVersionMinor int,
		SoftwareVersionBuild int,
		MachineName varchar(128),
		Flags int NULL,
		BindingId uniqueidentifier NULL,
		RecoveryForkID uniqueidentifier NULL,
		Collation varchar(128) null,
		FamilyGUID uniqueidentifier NULL,
		HasBulkLoggedData int,
		IsSnapshot int,
		IsReadOnly int,
		IsSingleUser int,
		HasBackupChecksums int,
		IsDamaged int,
		BeginsLogChain int,
		HasIncompleteMetaData int,
		IsForceOffline int,
		IsCopyOnly int,
		FirstRecoveryForkID uniqueidentifier NULL,
		ForkPointLSN  numeric(25,0) NULL,
		RecoveryModel varchar(60),
		DifferentialBaseLSN numeric(25,0) NULL,
		DifferentialBaseGUID uniqueidentifier NULL,
		BackupTypeDescription varchar(60),
		BackupSetGUID uniqueidentifier NULL,
		CompressedBackupSize bigint,
		Containment tinyint,
		KeyAlgorithm	nvarchar(32) NULL,
		EncryptorThumbprint	varbinary(20) NULL,
		EncryptorType	nvarchar(32) NULL
	)

SET @cmd = 'dir ' + @backup_log_path + '\*.trn /B'
 
BEGIN TRY   
	INSERT INTO #backup_list_T([FileName]) EXEC @result = sys.xp_cmdshell @cmd
END TRY
BEGIN CATCH
	THROW 51000, 'Error get files', 1;
END CATCH;

DELETE FROM #backup_list_T WHERE [FileName] IS NULL;

SET @ID = -1
WHILE (1 = 1)
BEGIN
	SELECT TOP 1
			@log_file_name = [FileName],
			@ID = ID
	FROM #backup_list_T
	WHERE ID > @ID

	IF @@ROWCOUNT = 0 BREAK

	TRUNCATE TABLE #backup_header
	SET @cmd = 'RESTORE HEADERONLY FROM DISK = ''' + @backup_log_path +'\'+ @log_file_name + '''' 
	INSERT INTO #backup_header
	EXECUTE(@cmd)

	UPDATE backup_list_T
	SET DatabaseName = bh.DatabaseName,
		FirstLSN = ISNULL(bh.FirstLSN, 0),
		LastLSN = ISNULL(bh.LastLSN, 0),
		BackupDate = bh.BackupFinishDate,
		ForkID = ISNULL(bh.RecoveryForkID, 0x01)
	FROM #backup_list_T backup_list_T, #backup_header bh
	WHERE backup_list_T.ID = @ID

END
DROP TABLE IF EXISTS #backup_header;

-- SORT LOGS
DECLARE @backup_list_V TABLE (
	ID INT IDENTITY(1,1) PRIMARY KEY CLUSTERED  NOT NULL,
	DatabaseName varchar(128),
	alsID INT,
	LogFileName VARCHAR(1000),
	FirstLSN NUMERIC(25, 0),
	State INT
	)

;WITH db_backup_lsn(DatabaseName, StartLSN) AS
	(
	SELECT
		d.name, 
		ISNULL(m.redo_start_lsn, 0)
	FROM
		sys.databases d 
	INNER JOIN 
		sys.master_files m
	ON 
		d.database_id = m.database_id AND
		m.type = 0
	)	

INSERT INTO @backup_list_V(alsID, DatabaseName, LogFileName, FirstLSN, State)
SELECT
	list.ID,
	list.DatabaseName,
	list.FileName,
	list.FirstLSN,
	1
FROM
	#backup_list_T list
INNER JOIN
	db_backup_lsn lastlsn
ON
	list.DatabaseName = lastlsn.DatabaseName
WHERE
	list.LastLSN > lastlsn.StartLSN
ORDER BY
	DatabaseName,
	LastLSN,
	FirstLSN

DROP TABLE IF EXISTS #backup_list_T

---------------------
--RESTORE LOG:
---------------------

IF @update_flag = 1
BEGIN
	SET @ID = -1
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@ID = ID,
			@DatabaseName = DatabaseName,
			@log_file_name = LogFileName
		FROM
			@backup_list_V
		WHERE
			ID > @ID
		ORDER BY
			ID

		IF @@ROWCOUNT = 0 BREAK

		SET @log_file_path = @backup_log_path +'\' + @log_file_name
		PRINT 'LOG RESTORING: ' + @log_file_path

		IF @recovery_flag = 0
		BEGIN
			RESTORE LOG @DatabaseName
			FROM DISK = @log_file_path
			WITH NORECOVERY;
		END 
		ELSE 
		BEGIN
			RESTORE LOG @DatabaseName
			FROM DISK = @log_file_path
		END 
	END
END
ELSE 
BEGIN
	SELECT 'RESTORE LOGs NECESSARY:'
	SELECT * FROM @backup_list_V
END;

END;