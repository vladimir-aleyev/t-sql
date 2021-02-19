
/*SQL Server 2008 Maintenance Plan or SSIS Package*/
--change the owner of a SQL Server 2008 Maintenance Plan or SSIS Package
UPDATE	[msdb].[dbo].[sysssispackages]
SET	[ownersid] = 0x01 --sa user
WHERE	[name] = 'YOUR_MAINT_PLAN_OR_PACKAGE'


/*SQL Server 2005 Maintenance Plan or SSIS Package*/
--change the owner of a SQL Server 2005 Maintenance Plan or SSIS Package
UPDATE	[msdb].[dbo].[sysdtspackages90]
SET	[ownersid] = 0x01 --sa user
WHERE	[name] = 'YOUR_MAINT_PLAN_OR_PACKAGE'


/*SQL Server 2000 Maintenance Plan*/
--change the owner of a SQL Server 2000 Maintenance Plan
UPDATE	[msdb].[dbo].[sysdbmaintplans]
SET	[owner] = 'sa'
WHERE	[plan_name] = 'YOUR_MAINT_PLAN'


/*SQL Server 2000 DTS package*/
--change the owner of a SQL Server 2000 DTS package
--note you need to update the owner column as well
UPDATE	[msdb].[dbo].[sysdtspackages]
SET	[owner] = 'sa',
	[owner_sid] = 0x01 --sa user
WHERE	[name] = 'YOUR_DTS_PACKAGE'
