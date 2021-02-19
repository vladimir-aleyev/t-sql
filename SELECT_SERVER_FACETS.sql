
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
      
SELECT
@SmoAuditLevel AS [AuditLevel],
ISNULL(@NumErrorLogs, -1) AS [NumberOfLogFiles],
(case when @SmoLoginMode < 3 then @SmoLoginMode else 9 end) AS [LoginMode],
ISNULL(@SmoMailProfile,N'') AS [MailProfile],
@BackupDirectory AS [BackupDirectory],
@SmoPerfMonMode AS [PerfMonMode],
ISNULL(@InstallSqlDataDir,N'') AS [InstallDataDirectory],
CAST(@@SERVICENAME AS sysname) AS [ServiceName],
@ErrorLogPath AS [ErrorLogPath],
@SmoRoot AS [RootDirectory],
CAST(case when 'a' <> 'A' then 1 else 0 end AS bit) AS [IsCaseSensitive],
@@MAX_PRECISION AS [MaxPrecision],
CAST(FULLTEXTSERVICEPROPERTY('IsFullTextInstalled') AS bit) AS [IsFullTextInstalled],
SERVERPROPERTY(N'ProductVersion') AS [VersionString],
CAST(SERVERPROPERTY(N'Edition') AS sysname) AS [Edition],
CAST(SERVERPROPERTY(N'ProductLevel') AS sysname) AS [ProductLevel],
CAST(SERVERPROPERTY('IsSingleUser') AS bit) AS [IsSingleUser],
CAST(SERVERPROPERTY('EngineEdition') AS int) AS [EngineEdition],
convert(sysname, serverproperty(N'collation')) AS [Collation],
CAST(SERVERPROPERTY('IsClustered') AS bit) AS [IsClustered],
CAST(SERVERPROPERTY(N'MachineName') AS sysname) AS [NetName],
@LogPath AS [MasterDBLogPath],
@MasterPath AS [MasterDBPath],
ISNULL(@SmoDefaultFile,N'') AS [DefaultFile],
ISNULL(@SmoDefaultLog,N'') AS [DefaultLog],
SERVERPROPERTY(N'ResourceVersion') AS [ResourceVersionString],
SERVERPROPERTY(N'ResourceLastUpdateDateTime') AS [ResourceLastUpdateDateTime],
SERVERPROPERTY(N'CollationID') AS [CollationID],
SERVERPROPERTY(N'ComparisonStyle') AS [ComparisonStyle],
SERVERPROPERTY(N'SqlCharSet') AS [SqlCharSet],
SERVERPROPERTY(N'SqlCharSetName') AS [SqlCharSetName],
SERVERPROPERTY(N'SqlSortOrder') AS [SqlSortOrder],
SERVERPROPERTY(N'SqlSortOrderName') AS [SqlSortOrderName],
SERVERPROPERTY(N'ComputerNamePhysicalNetBIOS') AS [ComputerNamePhysicalNetBIOS],
SERVERPROPERTY(N'BuildClrVersion') AS [BuildClrVersionString],
@ServiceStartMode AS [ServiceStartMode],
ISNULL(@ServiceAccount,N'') AS [ServiceAccount],
CAST(@NamedPipesEnabled AS bit) AS [NamedPipesEnabled],
CAST(@TcpEnabled AS bit) AS [TcpEnabled],
ISNULL(@InstallSharedDirectory,N'') AS [InstallSharedDirectory],
ISNULL(suser_sname(sid_binary(ISNULL(@SqlGroup,N''))),N'') AS [SqlDomainGroup],
case when 1=msdb.dbo.fn_syspolicy_is_automation_enabled() and exists (select * from msdb.dbo.syspolicy_system_health_state  where target_query_expression_with_id like 'Server%' ) then 1 else 0 end AS [PolicyHealthState],
@FilestreamLevel AS [FilestreamLevel],
ISNULL(@FilestreamShareName,N'') AS [FilestreamShareName],
-1 AS [TapeLoadWaitTime],
CAST(
        serverproperty(N'Servername')
       AS sysname) AS [Name],
CAST(
        ISNULL(serverproperty(N'instancename'),N'')
       AS sysname) AS [InstanceName],
CAST(0x0001 AS int) AS [Status],
0 AS [IsContainedAuthentication],
CAST(null AS int) AS [ServerType]