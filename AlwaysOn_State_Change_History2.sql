DECLARE @FileName NVARCHAR(4000)
SELECT @FileName = target_data.value('(EventFileTarget/File/@name)[1]', 'nvarchar(4000)')
    FROM (
           SELECT CAST(target_data AS XML) target_data
            FROM sys.dm_xe_sessions s
            JOIN sys.dm_xe_session_targets t
                ON s.address = t.event_session_address
            WHERE s.name = N'AlwaysOn_health'
         ) ft;

WITH    base
          AS (
               SELECT XEData.value('(event/@timestamp)[1]', 'datetime2(3)') AS event_timestamp
                   ,XEData.value('(event/data/text)[1]', 'VARCHAR(255)') AS previous_state
                   ,XEData.value('(event/data/text)[2]', 'VARCHAR(255)') AS current_state
                   ,ar.replica_server_name
                FROM (
                       SELECT CAST(event_data AS XML) XEData
                           ,*
                        FROM sys.fn_xe_file_target_read_file(@FileName, NULL, NULL, NULL)
                        WHERE object_name = 'availability_replica_state_change'
                     ) event_data
                JOIN sys.availability_replicas ar
                    ON ar.replica_id = XEData.value('(event/data/value)[5]', 'VARCHAR(255)')
             )
    SELECT DATEADD(HOUR, DATEDIFF(HOUR, GETUTCDATE(), GETDATE()), event_timestamp) AS event_timestamp
           ,previous_state
           ,current_state
           ,replica_server_name
        FROM base
        ORDER BY event_timestamp DESC;