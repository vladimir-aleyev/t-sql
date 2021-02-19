USE [msdb]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_DBA_InsertForSQL_StatementExecStat]
	@koef DECIMAL(12,2)=0.0 --коэффициент сбора,
	--подбирается экспериментальным путем для более точного сбора,
	--в большинстве случаев можно оставить 0.0,
	--если частота запуска сбора не будет превышать 5 минут
	--на точность расчетов влияет частота сбора и коэффициент сбора
	--чем чаще запуск сбора, тем меньше влияет коэффициент сбора
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @AvgCPU_Time BIGINT
       ,@MaxAvgCPU_Time BIGINT
	   ,@AvgTotalWorkerTime BIGINT
	   ,@MaxTotalWorkerTime BIGINT
	   ,@AvgAvgElapsedTime BIGINT
	   ,@MaxAvgElapsedTime BIGINT
	   ,@AvgTotalElapsedTime BIGINT
	   ,@MaxTotalElapsedTime BIGINT
	
	SELECT
		@AvgCPU_Time			= AVG(AvgCPU_Time),
		@MaxAvgCPU_Time			= max(AvgCPU_Time),
		@AvgTotalWorkerTime		= AVG(TotalWorkerTime),
		@MaxTotalWorkerTime		= max(TotalWorkerTime),
		@AvgAvgElapsedTime		= AVG(AvgElapsedTime),
		@MaxAvgElapsedTime		= max(AvgElapsedTime),
		@AvgTotalElapsedTime	= AVG(TotalElapsedTime),
		@MaxTotalElapsedTime	= max(TotalElapsedTime)
	FROM dbo.DBA_vStatementExecInfo;
	
	INSERT INTO dbo.DBA_SQL_StatementExecStat
	(
		[InsertDate]
	   ,[QueryHash]
	   ,[ExecutionCount]
	   ,[TotalWorkerTime]
	   ,[StatementText]
	   ,[TotalElapsedTime])
	SELECT
		GETDATE()
	   ,[QueryHash]
	   ,[ExecutionCount]
	   ,[TotalWorkerTime]
	   ,[StatementText]
	   ,[TotalElapsedTime]
	FROM dbo.DBA_vStatementExecInfo
	WHERE(AvgCPU_Time      > @AvgCPU_Time		  + @koef * (@MaxAvgCPU_Time	  - @AvgCPU_Time))
	  or (TotalWorkerTime  > @AvgTotalWorkerTime  + @koef * (@MaxTotalWorkerTime  - @AvgTotalWorkerTime))
	  or (AvgElapsedTime   > @AvgAvgElapsedTime   + @koef * (@MaxAvgElapsedTime   - @AvgAvgElapsedTime))
	  or (TotalElapsedTime > @AvgTotalElapsedTime + @koef * (@MaxTotalElapsedTime - @AvgTotalElapsedTime));
END

GO