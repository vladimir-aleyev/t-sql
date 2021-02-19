
----Backup LOG

DECLARE @DBNAME NVARCHAR(50)
DECLARE @FILENAME nvarchar(150)
DECLARE @timestamp datetime
DECLARE @PATH NVARCHAR(255)
DECLARE @SQL NVARCHAR(MAX)


SET @DBNAME = 'CitrixXenDesktopDB' --What
SET @PATH = 'D:\BackupDB\CitrixXenDesktopDB\' --Where


SET @FILENAME = @DBNAME+'_backup_'+REPLACE((REPLACE(CAST(getdate() as nvarchar(50)), ' ','')),':','') +'.bak'
IF EXISTS(select 1
 from sys.databases
where name = @DBNAME and state =0)
BEGIN
SET @SQL = 'BACKUP DATABASE '+@DBNAME+' TO DISK=N'''+@path+'' + @FILENAME + ''' WITH RETAINDAYS = 14, NOFORMAT, NOINIT,  NAME = N'''+@FILENAME +''', SKIP, REWIND, NOUNLOAD, COMPRESSION'
exec sp_executesql @statement = @SQL
END


---backup LOG:

DECLARE @DBNAME NVARCHAR(50)
DECLARE @FILENAME nvarchar(150)
DECLARE @timestamp datetime
DECLARE @PATH NVARCHAR(255)
DECLARE @SQL NVARCHAR(MAX)


SET @DBNAME = 'CitrixXenApp65'
SET @PATH = 'D:\BackupDB\CitrixXenApp65_TransactionLogs\'
SET @FILENAME = @DBNAME+'_backup_'+REPLACE((REPLACE(CAST(getdate() as nvarchar(50)), ' ','')),':','') +'.trn'
IF EXISTS(select 1
 from sys.databases
where name = @DBNAME and state =0)
BEGIN
SET @SQL = 'BACKUP LOG ['+@DBNAME+'] TO DISK=N'''+@path+'' + @FILENAME + ''' WITH RETAINDAYS = 14, NOFORMAT, NOINIT,  NAME = N'''+@FILENAME +''', SKIP, REWIND, NOUNLOAD, COMPRESSION'
exec sp_executesql @statement = @SQL
END