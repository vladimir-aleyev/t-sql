select
	'create login ['+name+'] with
	password = '+convert(varchar(max),password_hash,1)+' hashed,
	sid = '+convert(varchar(max),sid,1)+',
	default_database = ['+default_database_name+'],
	default_language = '+default_language_name+',
	check_expiration = '+CASE WHEN is_expiration_checked = 0 THEN 'off' ELSE 'on' END + ',
	check_policy = '+CASE WHEN is_policy_checked = 0 THEN 'off' ELSE 'on' END + '
	go
	alter login ['+name+'] '+  case when is_disabled=1 	then 'disable' else 'enable' end + ' go' as SQL_COMMAND
from
	sys.sql_logins
where
	sid != 0x01
and name not like '##%'

union all

select 'create login ['+name+'] from windows with
	default_database = ['+default_database_name+'],
	default_language = '+default_language_name+'
go
alter login ['+name+'] '+case when is_disabled=1
	then 'disable' else 'enable'
end+'
go'
from sys.server_principals
where type = 'U'
and name not like 'NT AUTHORITY\%'
and name not like 'NT Service\%'

union all

select
	'alter server role '+txt+' add member ['+loginname+']
go'
from sys.syslogins l
cross apply
		(values
			(denylogin,'denylogin'),
			(sysadmin,'sysadmin'),
			(securityadmin,'securityadmin'),
			(serveradmin,'serveradmin'),
			(setupadmin,'setupadmin'),
			(processadmin,'processadmin'),
			(diskadmin,'diskadmin'),
			(dbcreator,'dbcreator'),
			(bulkadmin,'bulkadmin')
		) o (opt, txt)
where 
	sid != 0x01
	and name not like '##%'
	and name not like 'NT AUTHORITY\%'
	and name not like 'NT Service\%'
	and opt != 0
