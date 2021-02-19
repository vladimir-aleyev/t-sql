CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StoreKey123!@#';--CHECK:--SELECT name, database_id, is_master_key_encrypted_by_server, is_broker_enabled, service_broker_guid FROM sys.databases;SELECT * FROM sys.symmetric_keys;CREATE CERTIFICATE Endpoint1Cert WITH
SUBJECT = 'For Service Broker endpoint';SELECT * FROM master.sys.certificatesdeclare @Folder varchar(max) = 'D:\MSSQL'DECLARE @sql nvarchar(MAX)set @sql = ''

select

@sql += iif(pvt_key_encryption_type <> 'NA'

, 'BACKUP CERTIFICATE '+name+' TO FILE = '''+@Folder+'\'+name+''' WITH PRIVATE KEY (  FILE = '''+@Folder+'\'+name+'.KEY'' , ENCRYPTION BY PASSWORD = ''StoreKey123!@#'' )'+char(13)

 ,'BACKUP CERTIFICATE '+name+' TO FILE = '''+@Folder+'\'+name+''''+char(13))

from master.sys.certificates

print (@sql)



