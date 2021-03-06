
SELECT TOP(900) title, displayName, sAMAccountName, givenName, telephoneNumber, facsimileTelephoneNumber, sn 
--FROM OPENQUERY( ADSI, 'SELECT title, displayName, sAMAccountName, givenName, telephoneNumber, facsimileTelephoneNumber, sn  FROM ''LDAP://dc=autodoc-local,dc=ru'' WHERE sAMAccountType=805306368')
FROM OPENQUERY( ADSI, 'SELECT title, displayName, sAMAccountName, givenName, telephoneNumber, facsimileTelephoneNumber, sn  FROM ''LDAP://OU=Бухгалтерия,OU=Sklad,OU=ofs,OU=autodoc,DC=autodoc-local,DC=ru'' WHERE sAMAccountType=805306368')

SELECT TOP(10) * 
FROM OPENQUERY( ADSI, 'SELECT * FROM ''LDAP://dc=autodoc-local,dc=ru'' WHERE objectClass = ''person''')

SELECT 
	title, displayName, sAMAccountName, givenName, telephoneNumber, facsimileTelephoneNumber, sn 
FROM 
	OPENROWSET('ADSDSOObject','adsdatasource', 'SELECT title, displayName, sAMAccountName, givenName, telephoneNumber, facsimileTelephoneNumber, sn FROM ''LDAP://OU=Бухгалтерия,OU=Sklad,OU=ofs,OU=autodoc,DC=autodoc-local,DC=ru'' WHERE sAMAccountType=805306368')

SELECT 
	title, displayName, sAMAccountName, givenName, telephoneNumber, facsimileTelephoneNumber, sn 
FROM 
	OPENROWSET('ADSDSOObject','adsdatasource', 'SELECT title, displayName, sAMAccountName, givenName, telephoneNumber, facsimileTelephoneNumber, sn FROM ''LDAP://OU=ofso,OU=ofs,OU=autodoc,DC=autodoc-local,DC=ru'' WHERE sAMAccountType=805306368')
