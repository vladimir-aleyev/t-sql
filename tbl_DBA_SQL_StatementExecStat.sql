USE [msdb]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[DBA_SQL_StatementExecStat](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[InsertDate] [datetime] NULL,
	[QueryHash] [binary](8) NULL,
	[ExecutionCount] [bigint] NULL,
	[TotalWorkerTime] [bigint] NULL,
	[StatementText] [nvarchar](max) NULL,
	[TotalElapsedTime] [bigint] NULL,
 CONSTRAINT [PK_SQL_StatementExecStat] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_PADDING ON
GO