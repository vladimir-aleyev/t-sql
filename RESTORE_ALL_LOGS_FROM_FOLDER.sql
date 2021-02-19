DECLARE @ShadowPath varchar(200),
		@cmd varchar(1000),
		@ret int,
		@ID int,
		@LogFileName varchar(200),
		@db_backup_lsn numeric(25,0),
		@DB varchar(20),
		@Time datetime,
		@update_flag int,
		@with_flag int,
		@StandbyFile varchar(200),
		@disk varchar(1000)


SET @DB = 'naCitilink'
SET @ShadowPath = '\\sw0825.proc.vzb\SQL_Backup\TBSQL\'
SET @Time = '2016-10-10 15:00:00.000'
SET @update_flag = 0		-- 0 = просмотр необходимысти накаток, 1 = накатка логов
SET @with_flag = 1			-- 0 = standby, 1 = norecovery, 2 = recovery

IF (SELECT object_id('tempdb..#T')) IS NOT NULL	DROP TABLE #T
IF (SELECT object_id('tempdb..#backup_header')) IS NOT NULL	DROP TABLE #backup_header

CREATE TABLE #T (
	ID int IDENTITY(1,1) NOT NULL,
	FileName varchar(255),
	FirstLSN numeric(25,0),
	LastLSN numeric(25,0),
	BackupDate datetime,
	ForkID uniqueidentifier,
	PRIMARY KEY CLUSTERED(ID)
)

CREATE TABLE #backup_header	(
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
	CompressedBackupSize int,
	Containment int,
	KeyAlgorithm  varchar(60) NULL,
	EncryptorThumbprint varchar(60) NULL,
	EncryptorType varchar(60) NULL
)


SET @cmd = 'dir ' + @ShadowPath + '*.trn /B' 

--EXEC master..xp_cmdshell @cmd

INSERT INTO #T(FileName)
EXEC @ret = master..xp_cmdshell @cmd

DELETE FROM #T WHERE FileName IS NULL

IF @ret <> 0
BEGIN
	RAISERROR(N'Error get files', 50001,1)
	GOTO EndFalse
END


SELECT 
	@db_backup_lsn = ISNULL(m.redo_start_lsn, 0)
FROM
	sys.databases d 
INNER JOIN 
	sys.master_files m
ON 
	d.database_id = m.database_id AND
	m.type = 0 
WHERE d.name = @DB

IF @db_backup_lsn = 0 OR @db_backup_lsn is null
BEGIN
	RAISERROR(N'Error get LSN database', 50001,1)
	GOTO EndFalse
END


SET @ID = -1
WHILE (1 = 1)
BEGIN
	SELECT TOP 1
			@LogFileName = FileName,
			@ID = ID
	FROM #T
	WHERE ID > @ID

	IF @@ROWCOUNT = 0 BREAK

	TRUNCATE TABLE #backup_header
	SET @cmd = 'RESTORE HEADERONLY FROM DISK = ''' + @ShadowPath+@LogFileName + '''' 
	INSERT INTO #backup_header
	EXECUTE(@cmd)

	UPDATE t
	SET FirstLSN = ISNULL(bh.FirstLSN, 0),
		LastLSN = ISNULL(bh.LastLSN, 0),
		BackupDate = bh.BackupFinishDate,
		ForkID = ISNULL(bh.RecoveryForkID, 0x01)
	FROM #T t, #backup_header bh
	WHERE t.ID = @ID
END
DROP TABLE #backup_header

-- выстраиваем логи в нужном порядке
DECLARE @t TABLE (
	ID INT NOT NULL IDENTITY(1,1),
	alsID INT,
	LogFileName VARCHAR(1000),
	FirstLSN NUMERIC(25, 0),
	State INT,
	PRIMARY KEY CLUSTERED (ID))

INSERT INTO @t(alsID, LogFileName, FirstLSN, State)
SELECT
	ID,
	FileName,
	FirstLSN,
	1
FROM
	#T
WHERE
	LastLSN > @db_backup_lsn AND
	BackupDate <= @Time
ORDER BY
	LastLSN,
	FirstLSN

INSERT INTO @t(alsID, LogFileName, FirstLSN, State)
SELECT TOP 1 ID, FileName,	FirstLSN, 0
FROM #T
WHERE BackupDate > @Time

IF @update_flag = 1
BEGIN
	SET @ID = -1
	WHILE 1=1
	BEGIN
		SELECT TOP 1
			@ID = ID,
			@LogFileName = LogFileName
		FROM
			@t
		WHERE
			ID > @ID
		ORDER BY
			ID

		IF @@ROWCOUNT = 0 BREAK

		SET @disk = @ShadowPath + @LogFileName
		SELECT 'Накатывается лог: ' + @disk

		IF @with_flag = 0
		BEGIN
			RESTORE LOG @DB
			FROM DISK = @disk
			
		END
		ELSE IF @with_flag = 1
		BEGIN
			RESTORE LOG @DB
			FROM DISK = @disk
			WITH NORECOVERY
		END 
		ELSE 
		BEGIN
			RESTORE LOG @DB
			FROM DISK = @disk
		END 
	END
END
ELSE 
BEGIN
	SELECT 'Необходимо накатить следующие логи:'
	SELECT * FROM @t
END

EndFalse:
	DROP TABLE #T

