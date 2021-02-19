--8<--------------- для SQL сервера 2005  и выше: ---------------------
USE [master]
GO
SELECT
	@@SERVERNAME AS 'Имя SQL сервера',
	COUNT(name) AS 'Количество пользователей',
	CASE [type] 
	WHEN 'S' THEN 'имя входа SQL'
	WHEN 'U' THEN 'имя входа Windows'
	WHEN 'G' THEN 'группа Windows'
	END  
	AS 'Тип пользователя'
FROM
	sys.server_principals
WHERE
	[TYPE] in ('S','U','G')
	AND
	is_disabled = 0
	AND [name] NOT LIKE '%NT SERVICE%'
	AND [name] NOT LIKE '%NT AUTHORITY%'
GROUP BY
	[TYPE]
--8<------------------------------------------------------	
	
	
USE [master]
GO
SELECT
	@@SERVERNAME AS 'Имя SQL сервера',
	*
FROM
	sys.server_principals
WHERE
	--[TYPE] in ('S','U','G')
	[TYPE] = 'G'
	AND
	is_disabled = 0
	AND [name] NOT LIKE '%NT SERVICE%'
	AND [name] NOT LIKE '%NT AUTHORITY%'



-- select * from sys.server_principals
-- select * from sys.database_principals


--8<--------------- для SQL сервера 2000: ---------------------

SELECT
	@@SERVERNAME AS 'Имя SQL сервера',
	'-----' AS 'База Данных',
	(SUM(hasaccess) - SUM(isntgroup) - SUM(isntgroup)) AS 'имя входа SQL',
	SUM(isntuser) AS 'имя входа Windows',
	SUM(isntgroup) AS 'группа Windows'
FROM
	dbo.syslogins
WHERE
	hasaccess = 1
	AND
	denylogin = 0
--8<-----------------------------------------------------------

select * from dbo.syslogins where isntgroup = 1