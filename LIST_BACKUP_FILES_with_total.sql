DECLARE @FileName VARCHAR(255)
DECLARE @File_Exists INT
DECLARE @DBname sysname
DECLARE @b_start DATETIME
DECLARE @b_end DATETIME
DECLARE @b_size NUMERIC(20,0)
DECLARE @type CHAR(1)

DROP TABLE IF EXISTS #backup_report
CREATE TABLE
	#backup_report
	(
	id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
	[database_name] SYSNAME,
	physical_device_name  VARCHAR(255),
	backup_start_date DATETIME,
	backup_finish_date DATETIME,
	CompressedBackupSizeKB NUMERIC(20,0),
	File_Exists INT,
	backup_type CHAR(1)
	)

DECLARE FileNameCsr CURSOR
READ_ONLY
FOR
		SELECT
			b.database_name,
			m.physical_device_name,
			b.backup_start_date,
			b.backup_finish_date,
			b.compressed_backup_size/1024.0 AS CompressedBackupSizeKB,
			--backup_size/1024.0 AS BackupSizeKB,
			b.[type]
		FROM
			msdb.dbo.backupset b
		INNER JOIN 
			msdb.dbo.backupmediafamily m ON b.media_set_id = m.media_set_id
		INNER JOIN 
			master..sysdatabases sd ON b.database_name = sd.name
		WHERE 
		--	database_name = [?]
		--	AND
			backup_finish_date > GETDATE() - 4  ---1 WEEK backup

		ORDER BY b.backup_finish_date DESC

BEGIN TRY
   OPEN FileNameCsr

   FETCH NEXT FROM FileNameCsr INTO @DBname, @FileName, @b_start, @b_end, @b_size, @type
   WHILE (@@fetch_status <> -1)
   BEGIN
       IF (@@fetch_status <> -2)
       BEGIN
		EXEC Master.dbo.xp_fileexist @FileName, @File_Exists OUT
		INSERT INTO #backup_report([database_name],physical_device_name,backup_start_date,backup_finish_date,CompressedBackupSizeKB,File_Exists,backup_type)
			VALUES(@DBName, @FileName, @b_start, @b_end, @b_size, @File_Exists, @type )
	   END
   
   FETCH NEXT FROM FileNameCsr INTO @DBname, @FileName, @b_start, @b_end, @b_size, @type
   END
   
END TRY

BEGIN CATCH
    SELECT
        ERROR_NUMBER() AS ErrorNumber
        ,ERROR_SEVERITY() AS ErrorSeverity
        ,ERROR_STATE() AS ErrorState
        ,ERROR_PROCEDURE() AS ErrorProcedure
        ,ERROR_LINE() AS ErrorLine
        ,ERROR_MESSAGE() AS ErrorMessage;
END CATCH


CLOSE FileNameCsr
DEALLOCATE FileNameCsr

SELECT * FROM #backup_report WHERE File_Exists = 1
ORDER BY
	database_name,backup_type, backup_start_date DESC;

SELECT database_name, backup_type, SUM(CompressedBackupSizeKB/1048576) AS	BackupSizeGB FROM  #backup_report GROUP BY database_name, backup_type  ORDER BY database_name;

--total by type--
SELECT backup_type, SUM(CompressedBackupSizeKB/1048576/*/8*/) AS	FULL_BackupSizeGB FROM  #backup_report WHERE backup_type = 'D' GROUP BY backup_type;  -- IN CASE OF FULL BACKUP split to 8 files: so /8 added

SELECT backup_type, SUM(CompressedBackupSizeKB/1048576) AS	DIFF_BackupSizeGB FROM  #backup_report WHERE backup_type = 'I' GROUP BY backup_type;

SELECT backup_type, SUM(CompressedBackupSizeKB/1048576) AS	LOG_BackupSizeGB FROM  #backup_report WHERE backup_type = 'L' GROUP BY backup_type;

DROP TABLE IF EXISTS #backup_report

GO


