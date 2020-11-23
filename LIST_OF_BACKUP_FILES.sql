/*list of backups*/
DECLARE @FileName varchar(255)
DECLARE @File_Exists int

IF NOT EXISTS (SELECT [object_id] FROM tempdb.sys.objects (NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb.dbo.#backup_list_table'))
CREATE TABLE #backup_list_table
(
	[server] nvarchar(128),
	[database_name] nvarchar(128),
	[backup_start_date] datetime,
	[backup_finish_date] datetime,
	[backup_type] nvarchar(50),
	[backup_size_mb] int,
	[physical_device_name] nvarchar(260),
	[backupset_name] nvarchar(128),
	[file_exists] int
) 

INSERT INTO #backup_list_table
SELECT
	CONVERT(CHAR(100), Serverproperty('Servername')) AS Server, 
	msdb.dbo.backupset.database_name, 
    msdb.dbo.backupset.backup_start_date, 
    msdb.dbo.backupset.backup_finish_date, 
    CASE msdb..backupset.type 
		WHEN 'D' THEN 'Database' 
        WHEN 'L' THEN 'Log'
        WHEN 'I' THEN 'Differencial'
		WHEN 'F' THEN 'File'
		WHEN 'G' THEN 'Differential file'
		WHEN 'P' THEN 'Partial'
		WHEN 'Q' THEN 'Differential partial'
    END                                             AS backup_type, 
    CAST((msdb.dbo.backupset.backup_size/1024/1024) AS int) AS 'backup_size (Mb)', 
    msdb.dbo.backupmediafamily.physical_device_name,  
    msdb.dbo.backupset.name                          AS backupset_name,
    NULL
FROM
	msdb.dbo.backupmediafamily
	INNER JOIN
	msdb.dbo.backupset
	ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id
WHERE
	( CONVERT(DATETIME, msdb.dbo.backupset.backup_start_date, 102) >= Getdate() - 7 )

DECLARE backup_list_cur CURSOR
FOR SELECT physical_device_name FROM #backup_list_table 

OPEN backup_list_cur
FETCH NEXT FROM backup_list_cur INTO @FileName
WHILE @@FETCH_STATUS = 0
BEGIN
		EXEC master.dbo.xp_fileexist @FileName, @File_Exists OUT
		UPDATE 
			#backup_list_table
		SET 
			file_exists = @File_Exists
		WHERE
			#backup_list_table.physical_device_name = @FileName	 
			AND
			backup_start_date = (SELECT MAX(backup_start_date) FROM #backup_list_table WHERE physical_device_name = @FileName)
	FETCH NEXT FROM backup_list_cur INTO @FileName
END

CLOSE backup_list_cur
DEALLOCATE backup_list_cur

SELECT
	*
FROM
	#backup_list_table
WHERE
	file_exists = 1
ORDER BY
	database_name,
	backup_start_date DESC

DROP TABLE #backup_list_table
