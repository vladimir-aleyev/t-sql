USE [master]
GO
CREATE CREDENTIAL [##xp_cmdshell_proxy_account##] WITH IDENTITY = N'VOZ\amlsql_test', SECRET = N'<password>'
GO


USE [msdb]
GO
EXEC msdb.dbo.sp_add_proxy @proxy_name=N'##xp_cmdshell_proxy_account##',@credential_name=N'##xp_cmdshell_proxy_account##', 
		@enabled=1
GO
EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=N'##xp_cmdshell_proxy_account##', @subsystem_id=3
GO
EXEC msdb.dbo.sp_grant_login_to_proxy @proxy_name=N'##xp_cmdshell_proxy_account##', @login_name=N'VOZ\amlsql_test'
GO


-- Log on as a batch job
-- Act as part of the operating system
-- Log on as a batch job

