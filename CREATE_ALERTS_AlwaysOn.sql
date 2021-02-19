USE [msdb]
GO

/****** Object:  Alert [AlwaysOn - Data Movement Resumed]    Script Date: 10/18/2016 3:28:47 PM ******/
EXEC msdb.dbo.sp_add_alert @name=N'AlwaysOn - Data Movement Resumed', 
		@message_id=35265, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

EXEC msdb.dbo.sp_add_notification @alert_name=N'AlwaysOn - Data Movement Resumed', @operator_name=N'DBA_operator', @notification_method = 1
GO

/****** Object:  Alert [AlwaysOn - Data Movement Suspended]    Script Date: 10/18/2016 3:28:58 PM ******/
EXEC msdb.dbo.sp_add_alert @name=N'AlwaysOn - Data Movement Suspended', 
		@message_id=35264, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

EXEC msdb.dbo.sp_add_notification @alert_name=N'AlwaysOn - Data Movement Suspended', @operator_name=N'DBA_operator', @notification_method = 1
GO

/****** Object:  Alert [AlwaysOn - Role Changed]    Script Date: 10/18/2016 3:29:05 PM ******/
EXEC msdb.dbo.sp_add_alert @name=N'AlwaysOn - Role Changed', 
		@message_id=1480, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=0, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'


EXEC msdb.dbo.sp_add_notification @alert_name=N'AlwaysOn - Role Changed', @operator_name=N'DBA_operator', @notification_method = 1
GO