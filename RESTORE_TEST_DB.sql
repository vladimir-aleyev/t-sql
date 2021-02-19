 
 CREATE PROCEDURE dbo.DBA_Restore_All_Backups
  /*Restore all database from full backup files from specific folder to server's default location*/
	@backup_path  VARCHAR(500) = '\\WBSERV\_SQLBackupData',
	@default_data_path VARCHAR(128) = NULL,
	@default_log_path VARCHAR(128) = NULL,
	@Input_DatabaseName VARCHAR(128) = 'All',
	@Norecovery_flg CHAR = 'N' 
 AS
 SET NOCOUNT ON;
 BEGIN
 
 DECLARE @cmd VARCHAR(1000)
 DECLARE @backup_list TABLE ([File] varchar(1000))
 DECLARE @backup_file VARCHAR(100)
 DECLARE @DatabaseName VARCHAR(128)
 DECLARE @data_file_name VARCHAR(128)
 DECLARE @log_file_name VARCHAR(128)
 DECLARE @data_file_path VARCHAR(128)
 DECLARE @log_file_path VARCHAR(128)
 --DECLARE @default_data_path VARCHAR(128)
 --DECLARE @default_log_path VARCHAR(128)
 DECLARE @rc1 INT;
 DECLARE @rc2 INT;

 CREATE TABLE #backup_filelist(
		LogicalName nvarchar(128),
		PhysicalName nvarchar(260),
		Type char(1),
		FileGroupName nvarchar(128) NULL,
		Size numeric(20,0),
		MaxSize numeric(20,0),
		FileID bigint,
		CreateLSN numeric(25,0),
		DropLSN numeric(25,0) NULL,
		UniqueID uniqueidentifier,
		ReadOnlyLSN numeric(25,0) NULL,
		ReadWriteLSN numeric(25,0) NULL,
		BackupSizeInBytes bigint,
		SourceBlockSize int,
		FileGroupID int,
		LogGroupGUID uniqueidentifier NULL,
		DifferentialBaseLSN numeric(25,0) NULL,
		DifferentialBaseGUID uniqueidentifier,
		IsReadOnly bit,
		IsPresent bit,
		TDEThumbprint varbinary(32)
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
		CompressedBackupSize bigint
	)

SET @cmd = 'dir /B ' + @backup_path
IF @default_data_path IS NULL 
	EXECUTE @rc1 = master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer',N'DefaultData', @default_data_path output, 'no_output';
IF @default_log_path IS NULL
	EXECUTE @rc2 = master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer',N'DefaultLog', @default_log_path output, 'no_output'; 
  
INSERT INTO @backup_list EXEC sys.xp_cmdshell @cmd
DECLARE DB_Cur CURSOR FOR SELECT [File] FROM @Backup_list WHERE [File] IS NOT NULL 
OPEN DB_Cur
FETCH NEXT FROM DB_Cur INTO @backup_file
WHILE @@FETCH_STATUS = 0
	BEGIN 	
		TRUNCATE TABLE #backup_header
		TRUNCATE TABLE #backup_filelist
		
		SET @cmd = 'RESTORE HEADERONLY FROM DISK = ''' + @backup_path +'\'+ @backup_file + '''' 
		INSERT INTO #backup_header EXECUTE(@cmd)
		
		SELECT @DatabaseName = DatabaseName FROM #backup_header

		IF @Input_DatabaseName = @DatabaseName OR @Input_DatabaseName = 'All'
		BEGIN
			SET @DatabaseName = '[' + @DatabaseName + ']'; 	
			SET @cmd = 'RESTORE FILELISTONLY FROM DISK = ''' + @backup_path +'\'+ @backup_file + '''' 
			INSERT INTO  #backup_filelist EXECUTE(@cmd)
			SELECT TOP(1) @data_file_name = LogicalName, @data_file_path = RIGHT(PhysicalName,CHARINDEX('\',REVERSE(PhysicalName))) FROM #backup_filelist WHERE Type = 'D'
 			SELECT TOP(1) @log_file_name = LogicalName, @log_file_path = RIGHT(PhysicalName,CHARINDEX('\',REVERSE(PhysicalName)))  FROM #backup_filelist WHERE Type = 'L'
			IF @Norecovery_flg = 'Y'
				SET @cmd = ''
			ELSE
				SET @cmd = 'ALTER DATABASE ' + @DatabaseName + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;' + CHAR(10);
			SET @cmd  = @cmd + 'RESTORE DATABASE ' +CHAR(10)+ @DatabaseName +CHAR(10)+ 'FROM ' + CHAR(10) + ' DISK = ''' + @backup_path +'\'+ @backup_file + '''' +CHAR(10)+
			+ 'WITH' + CHAR(10) + ' MOVE ''' + @data_file_name + ''' TO ''' + @default_data_path + @data_file_path + ''',' + CHAR(10) + ' MOVE ''' + @log_file_name + ''' TO ''' + @default_log_path + @log_file_path + '''' + ',' + CHAR(10) + ' REPLACE';
			IF @Norecovery_flg = 'Y'
				SET @cmd = @cmd + ',NORECOVERY;'  + CHAR(10)
			ELSE
			BEGIN	
				SET @cmd = @cmd + ';'  + CHAR(10)
				SET @cmd = @cmd + 'ALTER DATABASE ' + @DatabaseName + ' SET MULTI_USER;' + CHAR(10);
			END
			--PRINT @cmd
			EXECUTE(@cmd)
		END
		FETCH NEXT FROM DB_Cur INTO @backup_file
	END
CLOSE DB_Cur
DEALLOCATE DB_Cur

DROP TABLE #backup_header;
DROP TABLE #backup_filelist;

END;
