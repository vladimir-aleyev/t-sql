USE [msdb]
GO

/****** Object:  Table [dbo].[DBA_WhoIsActive]    Script Date: 09/11/2014 17:19:23 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[DBA_WhoIsActive](
	[dd hh:mm:ss.mss] [varchar](8000) NULL,
	[session_id] [smallint] NOT NULL,
	[sql_text] [xml] NULL,
	[sql_command] [xml] NULL,
	[login_name] [nvarchar](128) NULL,
	[wait_info] [nvarchar](4000) NULL,
	[tasks] [varchar](30) NULL,
	[CPU] [varchar](30) NULL,
	[tempdb_allocations] [varchar](30) NULL,
	[tempdb_current] [varchar](30) NULL,
	[blocking_session_id] [smallint] NULL,
	[reads] [varchar](30) NULL,
	[writes] [varchar](30) NULL,
	[context_switches] [varchar](30) NULL,
	[physical_io] [varchar](30) NULL,
	[physical_reads] [varchar](30) NULL,
	[used_memory] [varchar](30) NULL,
	[status] [varchar](30) NULL,
	[open_tran_count] [varchar](30) NULL,
	[percent_complete] [varchar](30) NULL,
	[host_name] [nvarchar](128) NULL,
	[database_name] [nvarchar](128) NULL,
	[program_name] [nvarchar](128) NULL,
	[additional_info] [xml] NULL,
	[start_time] [datetime] NULL,
	[login_time] [datetime] NULL,
	[request_id] [int] NULL,
	[collection_time] [datetime] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO




