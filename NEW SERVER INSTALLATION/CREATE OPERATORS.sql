USE [msdb]
GO

/****** Object:  Operator [CL_DBA_ALERT]    Script Date: 03.08.2020 13:18:34 ******/
EXEC msdb.dbo.sp_add_operator @name=N'CL_DBA_ALERT', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'DBA@citilink.ru', 
		@category_name=N'[Uncategorized]'
GO


USE [msdb]
GO

/****** Object:  Operator [CL_DBA_JOBS]    Script Date: 03.08.2020 13:18:43 ******/
EXEC msdb.dbo.sp_add_operator @name=N'CL_DBA_JOBS', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'DBA@citilink.ru', 
		@category_name=N'[Uncategorized]'
GO


USE [msdb]
GO

/****** Object:  Operator [DBA_CITILINK]    Script Date: 03.08.2020 13:18:50 ******/
EXEC msdb.dbo.sp_add_operator @name=N'DBA_CITILINK', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'DBA@citilink.ru', 
		@pager_address=N'CL_DBA', 
		@category_name=N'[Uncategorized]'
GO

/****** Object:  Operator [dba_alert]    Script Date: 10.11.2020 14:58:20 ******/
EXEC msdb.dbo.sp_add_operator @name=N'DBA_ALERT', 
		@enabled=1, 
		@weekday_pager_start_time=90000, 
		@weekday_pager_end_time=180000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=0, 
		@email_address=N'dba_alert@merlion.ru', 
		@category_name=N'[Uncategorized]'
GO