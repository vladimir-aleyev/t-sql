USE [msdb]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DBA_SQL_TopProcedureExecStat](
	[Row_GUID] [uniqueidentifier] NOT NULL,
	[SERVER] [nvarchar](255) NOT NULL,
	[DB_ID] [int] NOT NULL,
	[OBJECT_ID] [int] NOT NULL,
	[ExecutionCount] [bigint] NOT NULL,
	[TotalWorkerTime] [bigint] NULL,
	[TotalElapsedTime] [bigint] NULL,
	[Func] [decimal](8, 2) NULL,
	[AvgWorkerSec] [decimal](8, 2) NULL,
	[AvgElapsedSec] [decimal](8, 2) NULL,
	[DB_NAME] [nvarchar](255) NULL,
	[SCHEMA_NAME] [nvarchar](255) NULL,
	[OBJECT_NAME] [nvarchar](255) NULL,
	[InsertUTCDate] [datetime] NOT NULL,
	[TotalPhysicalReads] [bigint] NULL,
	[TotalLogicalReads] [bigint] NULL,
	[TotalLogicalWrites] [bigint] NULL,
	[AvgPhysicalReads] [bigint] NULL,
	[AvgLogicalReads] [bigint] NULL,
	[AvgLogicalWrites] [bigint] NULL,
	[CategoryName] [nvarchar](255) NULL,
 CONSTRAINT [PK_DBA_SQL_TopProcedureExecStat] PRIMARY KEY CLUSTERED 
(
	[Row_GUID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[DBA_SQL_TopProcedureExecStat] ADD  CONSTRAINT [DF_DBA_SQL_TopProcedureExecStat_Row_GUID]  DEFAULT (newid()) FOR [Row_GUID]
GO

ALTER TABLE [dbo].[DBA_SQL_TopProcedureExecStat] ADD  CONSTRAINT [DF_DBA_SQL_TopProcedureExecStat_SERVER]  DEFAULT (@@servername) FOR [SERVER]
GO

ALTER TABLE [dbo].[DBA_SQL_TopProcedureExecStat] ADD  CONSTRAINT [DF_DBA_SQL_TopProcedureExecStat_InsertUTCDate]  DEFAULT (getutcdate()) FOR [InsertUTCDate]
GO