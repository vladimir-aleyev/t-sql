exec sp_configure 'show advanced options', 1
reconfigure;

exec sp_configure 'blocked process threshold (s)', 20;
reconfigure;
exec sp_configure 'Ad Hoc Distributed Queries', 1;
reconfigure;
exec sys.sp_configure N'backup checksum default', N'1'
RECONFIGURE WITH OVERRIDE
-- ”становить сжатие резервных копий по умолчанию:
EXEC sys.sp_configure N'backup compression default', N'1'
GO
RECONFIGURE WITH OVERRIDE
GO
-- активировать опцию Сoptimize for ad hoc workloadsТ:
EXEC sys.sp_configure N'optimize for ad hoc workloads', N'1'
GO
RECONFIGURE WITH OVERRIDE
GO
-- установить возможность удаленного Сdedicated administrator connection (DAC)Т:
EXEC sp_configure 'remote admin connections', 1;
GO
RECONFIGURE WITH OVERRIDE
GO
-- активировать возможность использовани€ 'Database Mail' на сервере:
EXEC sp_configure 'Database Mail XPs', 1;
GO
RECONFIGURE
GO
-- provide an MS DTC-coordinated distributed transaction that protects the ACID properties of transactions
EXEC sp_configure 'remote proc trans', 1;
GO
RECONFIGURE
GO
