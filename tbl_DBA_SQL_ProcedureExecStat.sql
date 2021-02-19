USE [msdb]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DBA_SQL_ProcedureExecStat](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[InsertDate] [datetime] NULL,
	[database_id] [int] NULL,
	[object_id] [int] NULL,
	[ExecutionCount] [bigint] NULL,
	[TotalWorkerTime] [bigint] NULL,
	[TotalElapsedTime] [bigint] NULL,
	[TotalPhysicalReads] [bigint] NULL,
	[TotalLogicalReads] [bigint] NULL,
	[TotalLogicalWrites] [bigint] NULL,
 CONSTRAINT [PK_SQL_ProcedureExecStat] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO