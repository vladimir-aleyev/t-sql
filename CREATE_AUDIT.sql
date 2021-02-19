
/*NOT APPLICABLE FOR MS SQL SERVER 2008R2 STANDARD EDITION*/

USE [master]
GO

DECLARE @servername NVARCHAR(128)
DECLARE @auditname NVARCHAR(128)
DECLARE @sqlcmd NVARCHAR(4000)

--------------------------------------------------------------------------------------
		declare @HkeyLocal nvarchar(18)
        declare @ServicesRegPath nvarchar(34)
        declare @SqlServiceRegPath sysname
        declare @BrowserServiceRegPath sysname
        declare @MSSqlServerRegPath nvarchar(31)
        declare @InstanceNamesRegPath nvarchar(59)
        declare @InstanceRegPath sysname
        declare @SetupRegPath sysname
        declare @NpRegPath sysname
        declare @TcpRegPath sysname
        declare @RegPathParams sysname
        declare @FilestreamRegPath sysname

        select @HkeyLocal=N'HKEY_LOCAL_MACHINE'

        -- Instance-based paths
        select @MSSqlServerRegPath=N'SOFTWARE\Microsoft\MSSQLServer'
        select @InstanceRegPath=@MSSqlServerRegPath + N'\MSSQLServer'
        select @FilestreamRegPath=@InstanceRegPath + N'\Filestream'
        select @SetupRegPath=@MSSqlServerRegPath + N'\Setup'
        select @RegPathParams=@InstanceRegPath+'\Parameters'

        -- Services
        select @ServicesRegPath=N'SYSTEM\CurrentControlSet\Services'
        select @SqlServiceRegPath=@ServicesRegPath + N'\MSSQLSERVER'
        select @BrowserServiceRegPath=@ServicesRegPath + N'\SQLBrowser'

        -- InstanceId setting
        select @InstanceNamesRegPath=N'SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'

        -- Network settings
        select @NpRegPath=@InstanceRegPath + N'\SuperSocketNetLib\Np'
        select @TcpRegPath=@InstanceRegPath + N'\SuperSocketNetLib\Tcp'
      
	    declare @SmoAuditLevel int
        exec master.dbo.xp_instance_regread @HkeyLocal, @InstanceRegPath, N'AuditLevel', @SmoAuditLevel OUTPUT
      
        declare @NumErrorLogs int
        exec master.dbo.xp_instance_regread @HkeyLocal, @InstanceRegPath, N'NumErrorLogs', @NumErrorLogs OUTPUT
      
	    declare @SmoLoginMode int
        exec master.dbo.xp_instance_regread @HkeyLocal, @InstanceRegPath, N'LoginMode', @SmoLoginMode OUTPUT
      
        declare @SmoMailProfile nvarchar(512)
        exec master.dbo.xp_instance_regread @HkeyLocal, @InstanceRegPath, N'MailAccountName', @SmoMailProfile OUTPUT
      
	    declare @BackupDirectory nvarchar(512)
        if 1=isnull(cast(SERVERPROPERTY('IsLocalDB') as bit), 0)
          select @BackupDirectory=cast(SERVERPROPERTY('instancedefaultdatapath') as nvarchar(512))
        else
          exec master.dbo.xp_instance_regread @HkeyLocal, @InstanceRegPath, N'BackupDirectory', @BackupDirectory OUTPUT
      
	    declare @SmoPerfMonMode int
        exec master.dbo.xp_instance_regread @HkeyLocal, @InstanceRegPath, N'Performance', @SmoPerfMonMode OUTPUT

        if @SmoPerfMonMode is null
        begin
        set @SmoPerfMonMode = 1000
        end
      
	    declare @InstallSqlDataDir nvarchar(512)
        exec master.dbo.xp_instance_regread @HkeyLocal, @SetupRegPath, N'SQLDataRoot', @InstallSqlDataDir OUTPUT
      
	    declare @Arg sysname
        declare @Param sysname
        declare @MasterPath nvarchar(512)
        declare @LogPath nvarchar(512)
        declare @ErrorLogPath nvarchar(512) ----!!!!
      	declare @n int

        select @n=0
        select @Param='dummy'
        while(not @Param is null)
        begin
        select @Param=null
        select @Arg='SqlArg'+convert(nvarchar,@n)

        exec master.dbo.xp_instance_regread @HkeyLocal, @RegPathParams, @Arg, @Param OUTPUT ----!!!!
        		
		if(@Param like '-d%')
        begin
        select @Param=substring(@Param, 3, 255)
        select @MasterPath=substring(@Param, 1, len(@Param) - charindex('\', reverse(@Param)))
        end
        else if(@Param like '-l%')
        begin
        select @Param=substring(@Param, 3, 255)
        select @LogPath=substring(@Param, 1, len(@Param) - charindex('\', reverse(@Param)))
        end
        else if(@Param like '-e%')
        begin
        select @Param=substring(@Param, 3, 255)
        
		select @ErrorLogPath=substring(@Param, 1, len(@Param) - charindex('\', reverse(@Param))) ---!!!
        
		end

        select @n=@n+1
        end
      
	    declare @SmoRoot nvarchar(512)
        exec master.dbo.xp_instance_regread @HkeyLocal, @SetupRegPath, N'SQLPath', @SmoRoot OUTPUT
      
        declare @SmoDefaultFile nvarchar(512)
        exec master.dbo.xp_instance_regread @HkeyLocal, @InstanceRegPath, N'DefaultData', @SmoDefaultFile OUTPUT
      
	    declare @SmoDefaultLog nvarchar(512)
        exec master.dbo.xp_instance_regread @HkeyLocal, @InstanceRegPath, N'DefaultLog', @SmoDefaultLog OUTPUT
      
	    declare @ServiceStartMode int
        EXEC master.sys.xp_instance_regread @HkeyLocal, @SqlServiceRegPath, N'Start', @ServiceStartMode OUTPUT
      
	    declare @ServiceAccount nvarchar(512)
        EXEC master.sys.xp_instance_regread @HkeyLocal, @SqlServiceRegPath, N'ObjectName', @ServiceAccount OUTPUT
      
	    declare @NamedPipesEnabled int
        exec master.dbo.xp_instance_regread @HkeyLocal, @NpRegPath, N'Enabled', @NamedPipesEnabled OUTPUT
      
	    declare @TcpEnabled int
        EXEC master.sys.xp_instance_regread @HkeyLocal, @TcpRegPath, N'Enabled', @TcpEnabled OUTPUT
      
	    declare @InstallSharedDirectory nvarchar(512)
        EXEC master.sys.xp_instance_regread @HkeyLocal, @SetupRegPath, N'SQLPath', @InstallSharedDirectory OUTPUT
      
	    declare @SqlGroup nvarchar(512)
        exec master.dbo.xp_instance_regread @HkeyLocal, @SetupRegPath, N'SQLGroup', @SqlGroup OUTPUT
      
	    declare @FilestreamLevel int
        exec master.dbo.xp_instance_regread @HkeyLocal, @FilestreamRegPath, N'EnableLevel', @FilestreamLevel OUTPUT
      
	    declare @FilestreamShareName nvarchar(512)
        exec master.dbo.xp_instance_regread @HkeyLocal, @FilestreamRegPath, N'ShareName', @FilestreamShareName OUTPUT

--------------------------------------------------------------------------------------
SELECT @servername = @@SERVERNAME

SET @auditname = @servername + '_DDL__Audit'

SET @sqlcmd  = 'CREATE SERVER AUDIT ['+@auditname+'] TO FILE (FILEPATH = N'''+@ErrorLogPath+''' , MAXSIZE = 100 MB , MAX_ROLLOVER_FILES = 10 , RESERVE_DISK_SPACE = OFF ) WITH (QUEUE_DELAY = 1000,ON_FAILURE = CONTINUE)'

PRINT @sqlcmd
EXEC sp_executesql @sqlcmd

SET @sqlcmd = 
'CREATE SERVER AUDIT SPECIFICATION [' + @servername + '_ServerAuditSpecification] FOR SERVER AUDIT [' + @auditname + ']
ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP),ADD (BACKUP_RESTORE_GROUP),ADD (AUDIT_CHANGE_GROUP),ADD (DBCC_GROUP),ADD (DATABASE_PERMISSION_CHANGE_GROUP),
ADD (DATABASE_OBJECT_PERMISSION_CHANGE_GROUP),ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP),ADD (SERVER_OBJECT_PERMISSION_CHANGE_GROUP),ADD (SERVER_PERMISSION_CHANGE_GROUP),
ADD (DATABASE_PRINCIPAL_IMPERSONATION_GROUP),ADD (SERVER_PRINCIPAL_IMPERSONATION_GROUP),ADD (DATABASE_CHANGE_GROUP),ADD (DATABASE_OBJECT_CHANGE_GROUP),
ADD (DATABASE_PRINCIPAL_CHANGE_GROUP),ADD (SCHEMA_OBJECT_CHANGE_GROUP),ADD (SERVER_OBJECT_CHANGE_GROUP),ADD (SERVER_PRINCIPAL_CHANGE_GROUP),ADD (DATABASE_OPERATION_GROUP),
ADD (APPLICATION_ROLE_CHANGE_PASSWORD_GROUP),ADD (LOGIN_CHANGE_PASSWORD_GROUP),ADD (SERVER_STATE_CHANGE_GROUP),ADD (DATABASE_OWNERSHIP_CHANGE_GROUP),ADD (DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP),
ADD (SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP),ADD (SERVER_OBJECT_OWNERSHIP_CHANGE_GROUP),ADD (TRACE_CHANGE_GROUP) WITH (STATE = ON)'

PRINT @sqlcmd
EXEC sp_executesql @sqlcmd


SET @sqlcmd = 'ALTER SERVER AUDIT [' + @auditname + '] WITH (STATE = ON)'
PRINT @sqlcmd
EXEC sp_executesql @sqlcmd
