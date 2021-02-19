
CREATE TRIGGER tr_Create_Database 
ON ALL SERVER 
FOR CREATE_DATABASE 
AS 
    DECLARE 
        @DatabaseName NVARCHAR(128),
		@CreatedBy NVARCHAR(128),
		@CreatedDate NVARCHAR(23),
		@SQL NVARCHAR(4000),
		@subj NVARCHAR(128),
		@message_body NVARCHAR(4000)
	

	SELECT	@DatabaseName = EVENTDATA().value('(/EVENT_INSTANCE/DatabaseName)[1]','NVARCHAR(128)');
	SELECT	@CreatedBy	= EVENTDATA().value('(/EVENT_INSTANCE/LoginName)[1]','NVARCHAR(128)');
	SELECT	@CreatedDate = EVENTDATA().value('(/EVENT_INSTANCE/PostTime)[1]','NVARCHAR(128)');
	SELECT	@SQL = EVENTDATA().value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]','NVARCHAR(4000)');
	SELECT	@subj = 'DATABASE CREATED: ' + @DatabaseName;
	SELECT @message_body = 'DATABASE ' + ISNULL(@DatabaseName,'') + ' CREATED AT '+ ISNULL(@CreatedDate,'') + ' BY ' + ISNULL(@CreatedBy,'') + ':' + CHAR(13)
	SELECT @message_body = @message_body + @SQL;
	
	EXEC [msdb].[dbo].[sp_send_dbmail]
					@profile_name = 'DBA_Profile',
					@recipients = 'Aleev.V@autodoc.ru',
					@subject = @subj,
					@body = @message_body,
					@query_result_header = 0,
					@query_result_width = 32767,
					@query_no_truncate = 1 
						    
GO


