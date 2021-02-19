/*
The number of rows in the largest table in the database.
*/
SELECT
	st.row_count, OBJECT_NAME(OBJECT_ID) TableName 
FROM
	sys.dm_db_partition_stats st
WHERE
	index_id < 2
ORDER BY
	st.row_count DESC