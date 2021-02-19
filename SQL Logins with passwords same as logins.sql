---SQL Logins with passwords same as logins
select serverproperty('machinename') as 'Server Name',
isnull(serverproperty('instancename'),serverproperty('machinename')) as 'Instance Name', 
name as 'Login With Password Same As Name'
from master.sys.sql_logins
where pwdcompare(name,password_hash) = 1
order by name
option (maxdop 1)





