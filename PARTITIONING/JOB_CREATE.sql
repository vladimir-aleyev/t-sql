--1--
TRUNCATE TABLE [dbo].[VtbAuthorization_stage];
--2--
ALTER TABLE [dbo].[VtbAuthorization] SWITCH PARTITION 1 TO [dbo].[VtbAuthorization_stage];
--3--

DECLARE @newrange DATETIME
DECLARE @oldrange DATETIME

SELECT 
	@oldrange = CAST(MIN(prv.value) AS DATETIME),
	@newrange = DATEADD(MM,1,CAST(MAX(prv.value) AS DATETIME))
FROM
	sys.partition_range_values prv
INNER JOIN
	sys.partition_functions pf
ON prv.function_id = pf.function_id
WHERE
	pf.name = 'pf_18MonthRight_datetime'
--SELECT @oldrange, @newrange;

ALTER PARTITION FUNCTION pf_18MonthRight_datetime() MERGE RANGE (@oldrange);
ALTER PARTITION SCHEME [ps_DATA_18MonthRight_datetime] NEXT USED [FG_ACTIVE_DATA];
ALTER PARTITION FUNCTION pf_18MonthRight_datetime() SPLIT RANGE (@newrange);




