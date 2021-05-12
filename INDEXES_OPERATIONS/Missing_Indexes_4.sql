WITH igd AS
	(
	SELECT
		*,
		ISNULL(equality_columns,'')+','+ISNULL(inequality_columns,'') AS ix_col 
	FROM 
		sys.dm_db_missing_index_details
	)

SELECT --top(10)
	'USE ['+DB_NAME(igd.database_id)+'];
	CREATE INDEX ['+'ix_'+REPLACE(CONVERT(VARCHAR(10),GETDATE(),120),'-','')+'_'+CONVERT(VARCHAR,igs.group_handle)+'] ON '+
	igd.[statement]+'('+
	CASE
		WHEN LEFT(ix_col,1)=',' THEN STUFF(ix_col,1,1,'')
		WHEN RIGHT(ix_col,1)=',' THEN REVERSE(STUFF(REVERSE(ix_col),1,1,''))
	ELSE ix_col
	END
	+') '+ISNULL('INCLUDE('+igd.included_columns+')','')+' WITH(ONLINE=on, MAXDOP=0) 
	GO
	' command -- Online index operations are available only in SQL Server Enterprise, Developer, and Evaluation editions.
	,igs.user_seeks
	,igs.user_scans
	,igs.avg_total_user_cost
	,igs.last_user_seek
	,igs.last_user_scan
	,igs.avg_user_impact
	,part.rows
FROM
	sys.dm_db_missing_index_group_stats AS igs
INNER JOIN
	sys.dm_db_missing_index_groups AS link ON link.index_group_handle = igs.group_handle
INNER JOIN
	igd ON link.index_handle = igd.index_handle
INNER JOIN
	sys.partitions part ON igd.object_id = part.object_id
WHERE
	igd.database_id = DB_ID()
	AND
	part.index_id < 2
ORDER BY
	igs.avg_total_user_cost * igs.user_seeks DESC

--SELECT TOP(5) * FROM sys.dm_db_missing_index_group_stats WHERE group_handle IN(50,588,42889,184439) ORDER BY last_user_seek;
--select TOP(5) * from sys.dm_db_missing_index_details  WHERE object_id = 351392371
--select TOP(5) * from sys.dm_db_missing_index_groups WHERE index_handle IN(184438,42888,49,587)