-- Read-only routing url generation script. 
-- Connect to each replica in your AlwaysOn cluster and run this script to get the read_only_routing_url for the replica. 
-- Then set this to the read_only_routing_url for the availability group replica => 
--    alter availability group MyAvailabilityGroup modify replica on N'ThisReplica' with (secondary_role(read_only_routing_url=N'<url>')) 
print 'Read-only-routing url script v.2012.1.24.1'

print 'This SQL Server instance version is [' + cast(serverproperty('ProductVersion') as varchar(256)) + ']'

if (ServerProperty('IsClustered') = 1) 
begin 
    print 'This SQL Server instance is a clustered SQL Server instance.' 
end 
else 
begin 
    print 'This SQL Server instance is a standard (not clustered) SQL Server instance.'    
end

if (ServerProperty('IsHadrEnabled') = 1) 
begin 
    print 'This SQL Server instance is enabled for AlwaysOn.' 
end 
else 
begin 
    print 'This SQL Server instance is NOT enabled for AlwaysOn.' 
end

-- Detect SQL Azure instance. 
declare @is_sql_azure bit 
set @is_sql_azure = 0

begin try 
    set @is_sql_azure = 1 
    exec('declare @i int set @i = sql_connection_mode()') 
    print 'This SQL Server instance is a Sql Azure instance.' 
end try 
begin catch 
    set @is_sql_azure = 0 
    print 'This SQL Server instance is NOT a Sql Azure instance.' 
end catch

-- Check that this is SQL 11 or later, otherwise fail fast. 
if (@@microsoftversion / 0x01000000 < 11 or @is_sql_azure > 0) 
begin 
    print 'This SQL Server instance does not support read-only routing, exiting script.' 
end 
else 
begin -- if server supports read-only routing

    -- Fetch the dedicated admin connection (dac) port. 
    -- Normally it's always port 1434, but to be safe here we fetch it from the instance. 
    -- We use this later to exclude the admin port from read_only_routing_url. 
    declare @dac_port int 
    declare @reg_value varchar(255) 
    exec xp_instance_regread 
        N'HKEY_LOCAL_MACHINE', 
        N'SOFTWARE\Microsoft\Microsoft SQL Server\\MSSQLServer\SuperSocketNetLib\AdminConnection\Tcp', 
        N'TcpDynamicPorts', 
        @reg_value output

    set @dac_port = cast(@reg_value as int)

    print 'This SQL Server instance DAC (dedicated admin) port is ' + cast(@dac_port as varchar(255)) 
    if (@dac_port = 0) 
    begin 
        print 'Note a DAC port of zero means the dedicated admin port is not enabled.' 
    end

    -- Fetch ListenOnAllIPs value. 
    -- If set to 1, this means the instance is listening to all IP addresses. 
    -- If set to 0, this means the instance is listening to specific IP addresses. 
    declare @listen_all int 
    exec xp_instance_regread 
        N'HKEY_LOCAL_MACHINE', 
        N'SOFTWARE\Microsoft\Microsoft SQL Server\\MSSQLServer\SuperSocketNetLib\Tcp', 
        N'ListenOnAllIPs', 
        @listen_all output

    if (@listen_all = 1) 
    begin 
        print 'This SQL Server instance is listening to all IP addresses (default mode).' 
    end 
    else 
    begin 
        print 'This SQL Server instance is listening to specific IP addresses (ListenOnAllIPs is disabled).' 
    end

    -- Check for dynamic port configuration, not recommended with read-only routing. 
    declare @tcp_dynamic_ports varchar(255) 
    exec xp_instance_regread 
        N'HKEY_LOCAL_MACHINE', 
        N'SOFTWARE\Microsoft\Microsoft SQL Server\\MSSQLServer\SuperSocketNetLib\Tcp\IPAll', 
        N'TcpDynamicPorts', 
        @tcp_dynamic_ports output

    if (@tcp_dynamic_ports = '0') 
    begin 
        print 'This SQL Server instance is listening on a dynamic tcp port, this is NOT A RECOMMENDED CONFIGURATION when using read-only routing, because the instance port can change each time the instance is restarted.' 
    end 
    else 
    begin 
        print 'This SQL Server instance is listening on fixed tcp port(s) (it is not configured for dynamic ports), this is a recommended configuration when using read-only routing.' 
    end

    -- Calculate the server domain and instance FQDN. 
    -- We use @server_domain later to build the FQDN to the clustered instance. 
    declare @instance_fqdn varchar(255) 
    declare @server_domain varchar(255)

    -- Get the instance FQDN using the xp_getnetname API 
    -- Note all cluster nodes must be in same domain, so this works for calculating cluster FQDN. 
    set @instance_fqdn = '' 
    exec xp_getnetname @instance_fqdn output, 1
	exec xp_getnetname @server_domain output, 2

    -- Remove embedded null character at end if found. 
    declare @terminator int 
    set @terminator = charindex(char(0), @instance_fqdn) - 1 
    if (@terminator > 0) 
    begin 
        set @instance_fqdn = substring(@instance_fqdn, 1, @terminator) 
    end

    -- Build @server_domain using @instance_fqdn. 
    set @server_domain = @instance_fqdn

    -- Remove trailing portion to extract domain name. 
    set @terminator = charindex('.', @server_domain) 
    if (@terminator > 0) 
    begin 
        set @server_domain = substring(@server_domain, @terminator+1, datalength(@server_domain)) 
    end 
    print 'This SQL Server instance resides in domain ''' +  @server_domain + ''''

    if (ServerProperty('IsClustered') = 1) 
    begin 
        -- Fetch machine name, which for a clustered SQL instance returns the network name of the virtual server. 
        -- Append @server_domain to build the FQDN. 
        set @instance_fqdn = cast(serverproperty('MachineName') as varchar(255)) + '.' + @server_domain 
    end

    declare @ror_url varchar(255) 
    declare @instance_port int

    set @ror_url = ''

    -- Get first available port for instance. 
    select 
    top 1    -- Select first matching port 
    @instance_port = port 
    from sys.dm_tcp_listener_states 
    where 
    type=0 -- Type 0 = TSQL (to avoid mirroring endpoint) 
    and 
    state=0    --  State 0 is online    
    and 
    port <> @dac_port -- Avoid DAC port (admin port) 
    and 
    -- Avoid availability group listeners 
    ip_address not in (select ip_address from sys.availability_group_listener_ip_addresses agls) 
    group by port        
    order by port asc  -- Pick first port in ascending order

    -- Check if there are multiple ports and warn if this is the case. 
    declare @list_of_ports varchar(max) 
    set @list_of_ports = ''

    select 
    @list_of_ports = @list_of_ports + 
        case datalength(@list_of_ports) 
        when 0 then cast(port as varchar(max)) 
        else ',' +  cast(port as varchar(max)) 
        end 
    from sys.dm_tcp_listener_states 
    where 
    type=0    --     Type 0 = TSQL (to avoid mirroring endpoint) 
    and 
    state=0    --  State 0 is online    
    and 
    port <> @dac_port -- Avoid DAC port (admin port) 
    and 
    -- Avoid availability group listeners 
    ip_address not in (select ip_address from sys.availability_group_listener_ip_addresses agls) 
    group by port        
    order by port asc

    print 'This SQL Server instance FQDN (Fully Qualified Domain Name) is ''' + @instance_fqdn + '''' 
    print 'This SQL Server instance port is ' + cast(@instance_port as varchar(10))

    set @ror_url = 'tcp://' + @instance_fqdn + ':' + cast(@instance_port as varchar(10))

    print '****************************************************************************************************************' 
    print 'The read_only_routing_url for this SQL Server instance is ''' + @ror_url + '''' 
    print '****************************************************************************************************************'

    -- If there is more than one instance port (unusual) list them out just in case. 
    if (charindex(',', @list_of_ports) > 0) 
    begin 
        print 'Note there is more than one instance port, the list of available instance ports for read_only_routing_url is (' + @list_of_ports + ')' 
        print 'The above URL just uses the first port in the list, but you can use any of these available ports.' 
    end

end -- if server supports read-only routing 
go


---CONNECT TO PRIMARY Server

---1 to configure current SECONDARY replica to allow read-only connections
ALTER AVAILABILITY GROUP [AvailabiltyGroup]
MODIFY REPLICA ON N'SecondaryServer' WITH (SECONDARY_ROLE(ALLOW_CONNECTIONS = READ_ONLY))

---2 to configure current SECONDARY replica  to accept read-only connections even after failover when it becomes primary
ALTER AVAILABILITY GROUP [AvailabiltyGroup]
MODIFY REPLICA ON N'SecondaryServer' WITH (PRIMARY_ROLE(ALLOW_CONNECTIONS = ALL))

---3 to specify which routing URLs are associated with each replica.
ALTER AVAILABILITY GROUP [AvailabiltyGroup]
MODIFY REPLICA ON N'PrimaryServer' WITH (SECONDARY_ROLE(READ_ONLY_ROUTING_URL = N'tcp://PrimaryServer.voz.ru:1433'))

ALTER AVAILABILITY GROUP [AvailabiltyGroup]
MODIFY REPLICA ON N'SecondaryServer' WITH (SECONDARY_ROLE(READ_ONLY_ROUTING_URL = N'tcp://SecondaryServer.voz.ru:1433'))

---4 to configure routing lists for current primary replica and future primary replica (current secondary replica).
-----First you configure read-only routing to the secondary replica SRV1(primary) -> SRV2(secondary). Then SRV2(secondary) -> SRV1(primary)
ALTER AVAILABILITY GROUP [AvailabiltyGroup]
MODIFY REPLICA ON N'PrimaryServer' WITH (PRIMARY_ROLE(READ_ONLY_ROUTING_LIST = (N'SecondaryServer',N'PrimaryServer')))

ALTER AVAILABILITY GROUP [AvailabiltyGroup]
MODIFY REPLICA ON N'SecondaryServer' WITH (PRIMARY_ROLE(READ_ONLY_ROUTING_LIST = (N'PrimaryServer',N'SecondaryServer')))


---CHECK
select g.name, r1.replica_server_name, l.routing_priority, r2.replica_server_name, r2.read_only_routing_url 
from sys.availability_read_only_routing_lists as l
join sys.availability_replicas as r1 on l.replica_id = r1.replica_id
join sys.availability_replicas as r2 on l.read_only_replica_id = r2.replica_id
join sys.availability_groups as g on r1.group_id = g.group_id

---SQLCMD.exe -S SW0229 -d VBANK_MSCRM -E -K ReadOnly