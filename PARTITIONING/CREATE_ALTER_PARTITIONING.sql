USE [Payture20]
GO
--1-- CREATE STAGING TABLE

CREATE TABLE [dbo].[VtbAuthorization_stage](
	[Id] [bigint] NOT NULL,
	[Date] [datetime] NOT NULL,
	[MerchantContractId] [int] NOT NULL,
	[MerchantOrderId] [varchar](50) NOT NULL,
	[ExpirationDatePlain] [varchar](4) NOT NULL,
	[PrimaryAccountNumberCipher] [varchar](50) NOT NULL,
	[PrimaryAccountNumberKeyId] [int] NOT NULL,
	[NoCVV] [bit] NOT NULL,
	[OriginalOrderId] [varchar](50) NULL,
	[CardAcceptorTerminalIdentification] [varchar](8) NULL,
	[Amount] [int] NOT NULL,
	[ProcessingOrderId] [varchar](12) NULL,
	[IpAddress] [varchar](15) NULL,
	[CustomerName] [varchar](15) NULL,
	[Phone] [varchar](11) NULL,
	[Email] [varchar](19) NULL,
	[RespCode] [varchar](3) NULL,
	[ApprovalCode] [varchar](6) NULL,
	[ClearingState] [int] NULL,
	[FileNumber] [int] NULL,
 CONSTRAINT [PK_VtbAuthorization_stage] PRIMARY KEY CLUSTERED 
(
	[Id] ASC,
	[Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [FG_ARCHIVE_DATA]
) ON [FG_ARCHIVE_DATA]

GO

--2-- CREATE PARTITION FUNCTION, PARTITION SCHEME:

----------Create list for partition function--------------------------------------
--DECLARE @newrange DATETIME
--DECLARE @oldrange DATETIME
--DECLARE @month SMALLINT
--DECLARE @range VARCHAR(4000)
--DECLARE @allrange VARCHAR(4000);

--SET @newrange = DATEADD(DAY,1,EOMONTH(GETDATE()));
--SET @oldrange = DATEADD(DAY,1,EOMONTH(GETDATE(),-19));

--SELECT @oldrange, @newrange;

--SET @month = -18
--SET @allrange = '';
--WHILE @month < 1
--	BEGIN
--	SET @range = CONVERT(VARCHAR(23), DATEADD(DAY,1,EOMONTH(GETDATE(),@month)), 126);
--	SET @month = @month + 1;
--	SET @allrange = @allrange + ''',''' + @range;
--	END;
--SELECT @allrange;
------------------------------------------------------------------------------------

CREATE PARTITION FUNCTION 
	[pf_18MonthRight_datetime](datetime) 
AS 
	RANGE RIGHT FOR VALUES 
(
'2019-10-01',
'2019-11-01',
'2019-12-01',
'2020-01-01',
'2020-02-01',
'2020-03-01',
'2020-04-01',
'2020-05-01',
'2020-06-01',
'2020-07-01',
'2020-08-01',
'2020-09-01',
'2020-10-01',
'2020-11-01',
'2020-12-01',
'2021-01-01',
'2021-02-01',
'2021-03-01',
'2021-04-01'
)
GO

USE [Payture20]
GO

CREATE PARTITION SCHEME [ps_DATA_18MonthRight_datetime] 
AS 
	PARTITION [pf_18MonthRight_datetime] 
TO (
	[FG_ACTIVE_DATA], 
	[FG_ACTIVE_DATA], 
	[FG_ACTIVE_DATA], 
	[FG_ACTIVE_DATA], 
	[FG_ACTIVE_DATA], 
	[FG_ACTIVE_DATA], 
	[FG_ACTIVE_DATA], 
	[FG_ACTIVE_DATA], 
	[FG_ACTIVE_DATA], 
	[FG_ACTIVE_DATA], 
	[FG_ACTIVE_DATA], 
	[FG_ACTIVE_DATA], 
	[FG_ACTIVE_DATA], 
	[FG_ACTIVE_DATA], 
	[FG_ACTIVE_DATA], 
	[FG_ACTIVE_DATA], 
	[FG_ACTIVE_DATA], 
	[FG_ACTIVE_DATA], 
	[FG_ACTIVE_DATA],
	[FG_ACTIVE_DATA]
	)
GO


--3-- DROP CLUSTERED INDEX

ALTER TABLE [dbo].[VtbAuthorization] DROP CONSTRAINT [PK_VtbAuthorization]
GO

--3a--- OPTIONAL: Create new to remove partitioning:
--ALTER TABLE [dbo].[VtbAuthorization_test] ADD  CONSTRAINT [PK_VtbAuthorization_test] PRIMARY KEY CLUSTERED 
--(
--	[Id] ASC,
--	[Date] ASC
--)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
--ON [FG_ACTIVE_DATA]
--GO



--4-- CREATE NEW CONSTRAINT WITH NEW PARTITION SCHEME

ALTER TABLE [dbo].[VtbAuthorization] ADD  CONSTRAINT [PK_VtbAuthorization] PRIMARY KEY CLUSTERED 
(
	[Id] ASC,
	[Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
ON ps_DATA_18MonthRight_datetime(Date)
GO


--5--- DROP AND CREATE NON CLUSTERED INDEX;

USE [Payture20]
GO

DROP INDEX [IX_VtbAuthorization__MerchantOrderId_MerchantContractId] ON [dbo].[VtbAuthorization]
GO


CREATE NONCLUSTERED INDEX [IX_VtbAuthorization__MerchantOrderId_MerchantContractId] ON [dbo].[VtbAuthorization]
(
	[MerchantOrderId] ASC,
	[MerchantContractId] ASC
)
INCLUDE ([Id],
	[Date]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	ON [FG_ACTIVE_INDEX]
GO


