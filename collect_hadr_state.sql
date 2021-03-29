USE [Mon]
GO
/****** Object:  StoredProcedure [dbo].[collect_hadr_state]    Script Date: 3/29/2021 5:28:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[collect_hadr_state]
AS
BEGIN

DECLARE @primary_replica NVARCHAR(256)
DECLARE @secondary_replica NVARCHAR(256)
DECLARE @database_name SYSNAME
DECLARE @redo_lag_secs BIGINT

;WITH 
	AG_Stats AS 
			(
			SELECT AR.replica_server_name,
				   HARS.role_desc, 
				   Db_name(DRS.database_id) [DBName], 
				   DRS.redo_queue_size redo_queue_size_KB,
				   DRS.redo_rate redo_rate_KB_Sec
			FROM   sys.dm_hadr_database_replica_states DRS 
			INNER JOIN sys.availability_replicas AR ON DRS.replica_id = AR.replica_id 
			INNER JOIN sys.dm_hadr_availability_replica_states HARS ON AR.group_id = HARS.group_id 
				AND AR.replica_id = HARS.replica_id 
			),
	Pri_CommitTime AS 
			(
			SELECT	replica_server_name
					, DBName
					, redo_queue_size_KB
					, redo_rate_KB_Sec
			FROM	AG_Stats
			WHERE	role_desc = 'PRIMARY'
			),
	Sec_CommitTime AS 
			(
			SELECT	replica_server_name
					, DBName
					--Send queue and rate will be NULL if secondary is not online and synchronizing
					, redo_queue_size_KB
					, redo_rate_KB_Sec
			FROM	AG_Stats
			WHERE	role_desc = 'SECONDARY'
			)

SELECT
	--GETDATE() AS collection_time,
	@primary_replica = p.replica_server_name --[primary_replica]
	,@database_name = p.[DBName] --AS [DatabaseName]
	,@secondary_replica = s.replica_server_name --[secondary_replica]
	,@redo_lag_secs = CAST(s.redo_queue_size_KB / s.redo_rate_KB_Sec AS BIGINT) --[Redo_Lag_Secs]
FROM Pri_CommitTime p
LEFT JOIN Sec_CommitTime s ON [s].[DBName] = [p].[DBName]

IF
 @redo_lag_secs > 1
	BEGIN
		INSERT INTO [dbo].[hadr_states]([collection_time],[primary_replica],[database_name],[secondary_replica],[redo_lag_secs]) 
		VALUES(GETDATE(), @primary_replica, @database_name,@secondary_replica, @redo_lag_secs)

-------------- REPORT------------
	DECLARE @tableHTML  NVARCHAR(MAX)  
	set @tableHTML =  
		N'<H3>AG Redo Latency detected on Server: '+ @@SERVERNAME + ', '+convert(nvarchar(20),GETDATE(),120)+'</H3>' + 
		N'<table border="1" align="center">' +  
		N'<th  align="center">PRIMARY REPLICA</th>'+ 
		N'<th  align="center">DATABASE NAME</th>'+
		N'<th  align="center">SECONDARY REPLICA</th>'+ 
		N'<th  align="center">REDO LAG (SECS)</th>'+ 
		N'</tr>'+
			CAST ( ( SELECT 
						td = @primary_replica,'',
						[td/@align]='right',
						td = @database_name,'',  
						[td/@align]='right',
						td = @secondary_replica,'',
						[td/@align]='right',
						td = @redo_lag_secs, '' 
					
				  FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX) ) +  
		N'</table>'  


		EXEC msdb.dbo.sp_send_dbmail  
			@profile_name = 'sql_mail',  
			@recipients =  'v.aleev@mail.ru',    
			@subject = 'AG Redo Latency detected', 
			@body=@tableHTML,
			@body_format = 'HTML'

	END;
	-------------------------------

END;