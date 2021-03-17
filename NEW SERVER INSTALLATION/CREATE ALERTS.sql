USE [msdb]
GO

/****** Object:  Alert [Severity 17]    Script Date: 03.08.2020 13:23:15 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 17 - Insufficient Resources', 
		@message_id=0, 
		@severity=17, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

/****** Object:  Alert [Severity 18]    Script Date: 03.08.2020 13:23:15 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 18', 
		@message_id=0, 
		@severity=18, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

/****** Object:  Alert [Severity 19]    Script Date: 03.08.2020 13:23:15 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 19', 
		@message_id=0, 
		@severity=19, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

/****** Object:  Alert [Severity 20]    Script Date: 03.08.2020 13:23:15 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 20', 
		@message_id=0, 
		@severity=20, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

/****** Object:  Alert [Severity 21]    Script Date: 03.08.2020 13:23:15 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 21', 
		@message_id=0, 
		@severity=21, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

/****** Object:  Alert [Severity 22]    Script Date: 03.08.2020 13:23:15 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 22', 
		@message_id=0, 
		@severity=22, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

/****** Object:  Alert [Severity 23]    Script Date: 03.08.2020 13:23:15 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 23', 
		@message_id=0, 
		@severity=23, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

/****** Object:  Alert [Severity 24]    Script Date: 03.08.2020 13:23:15 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 24', 
		@message_id=0, 
		@severity=24, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

/****** Object:  Alert [Severity 25]    Script Date: 03.08.2020 13:23:15 ******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 25', 
		@message_id=0, 
		@severity=25, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=1, 
		@category_name=N'[Uncategorized]', 
		@job_id=N'00000000-0000-0000-0000-000000000000'
GO

EXEC msdb.dbo.sp_add_alert @name=N'Blocking Process', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=0, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'MSSQL$MSSQLSERVER_01:General Statistics|Processes blocked||>|5'
GO


EXEC msdb.dbo.sp_add_alert @name=N'Number of Deadlocks', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=300, 
		@include_event_description_in=0, 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'MSSQL$MSSQLSERVER_01:Locks|Number of Deadlocks/sec|_Total|>|0'
GO

------------

EXEC msdb.dbo.sp_add_alert @name=N'Severity Level 823 Alert: Fatal Error - I/O Error',
  @message_id=823,
  @severity=0,
  @enabled=1,
  @delay_between_responses=300,
  @include_event_description_in=1
GO
 
EXEC msdb.dbo.sp_add_alert @name=N'Severity Level 824 Alert: Fatal Error - I/O Error',
  @message_id=824,
  @severity=0,
  @enabled=1,
  @delay_between_responses=300,
  @include_event_description_in=1
GO

EXEC msdb.dbo.sp_add_alert @name=N'Severity Level 825 Alert: Fatal Error - I/O Error',
  @message_id=825,
  @severity=0,
  @enabled=1,
  @delay_between_responses=300,
  @include_event_description_in=1
GO

