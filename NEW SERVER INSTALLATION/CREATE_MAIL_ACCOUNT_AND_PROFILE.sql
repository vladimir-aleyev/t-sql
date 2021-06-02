EXECUTE sp_configure 'show_advanced_options',1
GO
RECONFIGURE
GO
EXECUTE sp_configure 'Database Mail XPs',1 
GO
RECONFIGURE
GO

-- Create a Database Mail accounts:
EXECUTE msdb.dbo.sysmail_add_account_sp  
	@account_name = 'DBA_CITILINK',
	@email_address = '<@ServerName>@<host>.<com>',
	@display_name = '<@ServerName>@<host>.<com>',
	@replyto_address = 'DBA@@<host>.<com>',
	@mailserver_name = 'exch.<domain>.local', 
	@mailserver_type = 'SMTP',
	@port = 25,
	@use_default_credentials = 1,
	@enable_ssl = 0
	--[ , [ @account_id = ] account_id OUTPUT ]

EXECUTE msdb.dbo.sysmail_add_account_sp  
	@account_name = 'DBA_ALERT',
	@email_address = '<@ServerName>@<host>.<com>',
	@display_name = ' Alert <@ServerName>@<host>.<com>',
	@replyto_address = 'DBA@<host>.<com>' ,
	@mailserver_name = 'exch.<domain>.local', 
	@mailserver_type = 'SMTP',
	@port = 25,
	@use_default_credentials = 1,
	@enable_ssl = 0
	--[ , [ @account_id = ] account_id OUTPUT ]

EXECUTE msdb.dbo.sysmail_add_account_sp  
	@account_name = 'DBA_JOBS',
	@email_address = '<@ServerName>@<host>.<com>',
	@display_name = 'Jobs <@ServerName>@<host>.<com>',
	@replyto_address = 'DBA@<host>.<com>' ,
	@mailserver_name = 'exch.<domain>.local', 
	@mailserver_type = 'SMTP',
	@port = 25,
	@use_default_credentials = 1,
	@enable_ssl = 0
	--[ , [ @account_id = ] account_id OUTPUT ]


-- Create a Database Mail profiles:
EXECUTE msdb.dbo.sysmail_add_profile_sp
	@profile_name = 'DBA',
	@description = 'Profile used for administrative mail.';
 

EXECUTE msdb.dbo.sysmail_add_profile_sp
	@profile_name = 'DBA_ALERT',
	@description = 'Profile used for administrative mail.';


EXECUTE msdb.dbo.sysmail_add_profile_sp
	@profile_name = 'DBA_JOBS',
	@description = 'Profile used for administrative mail.';


-- Add the account to the profile:
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
	@profile_name = 'DBA',
	@account_name = 'DBA',
	@sequence_number =1 ;

EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
	@profile_name = 'DBA_ALERT',
	@account_name = 'DBA_ALERT',
	@sequence_number =1 ;

EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
	@profile_name = 'DBA_JOBS',
	@account_name = 'DBA_JOBS',
	@sequence_number =1 ;


