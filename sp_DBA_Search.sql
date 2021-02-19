CREATE OR ALTER PROCEDURE dbo.sp_DBA_Search
@search_str NVARCHAR(MAX) 
AS
SET NOCOUNT ON
BEGIN

IF @search_str IS NULL OR LEN(@search_str) < 5 BEGIN PRINT 'Parameter is empty or too short...' RETURN(1) END;

DECLARE @cmd		NVARCHAR(MAX);

SET @search_str = '%'+@search_str+'%'

SET @cmd = 
'
USE [?];
SELECT
	DB_NAME() AS [database],
	obj.name, 
	mdl.definition,
	obj.object_id, 
	obj.type, 
	obj.type_desc, 
	obj.create_date, 
	obj.modify_date, 
	obj.is_ms_shipped 
FROM
	sys.objects obj
INNER JOIN
	sys.sql_modules mdl
	ON
	obj.object_id = mdl.object_id

WHERE
	definition LIKE ''' + @search_str + '''';

DROP TABLE IF EXISTS #search_table
CREATE TABLE #search_table
(
	[database]	SYSNAME, 
	[name]		SYSNAME, 
	[definition] NVARCHAR(MAX),
	[object_id] INT ,
	type		CHAR(2),
	type_desc	NVARCHAR(60),
	create_date DATETIME,
	modify_date	DATETIME,
	is_ms_shipped BIT
)

INSERT INTO
	#search_table
EXECUTE sp_MSforEachDB @command1 = @cmd, @replacechar = '?'

SELECT 
	[database], 
	[name], 
	[definition],
	[object_id],
	[type],
	[type_desc],
	[create_date],
	[modify_date],
	[is_ms_shipped]
FROM
	#search_table
WHERE
	[definition] IS NOT NULL;

DROP TABLE IF EXISTS #search_table

END;

