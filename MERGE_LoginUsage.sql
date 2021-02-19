


MERGE
	msdb.dbo.DBA_LoginsUsage AS TARGET
USING
	(SELECT 
		MAX(login_time),
		login_name 
	FROM
		sys.dm_exec_sessions
	GROUP BY
		login_name ) AS SOURCE (login_time, login_name)
ON (TARGET.login_name = SOURCE.Login_name)
WHEN MATCHED THEN   
        UPDATE SET login_time = SOURCE.login_time  
WHEN NOT MATCHED THEN  
    INSERT (login_time, login_name) 
    VALUES (SOURCE.login_time, SOURCE.login_name)
OUTPUT deleted.*, $action, inserted.*	
;





