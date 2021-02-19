select sAMAccountName,CONVERT(uniqueidentifier,objectGUID) as Guid  from openquery
(ADSI,'select sAMAccountName,objectGUID from ''LDAP://cnt.voz.ru/DC=cnt,DC=voz,DC=ru'' where objectCategory=''Person''')
order by sAMAccountName


