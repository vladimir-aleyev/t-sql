/*
SELECT TOP 1000 [Id]
      ,[Date]
      ,[MerchantContractId]
      ,[MerchantOrderId]
      ,[ExpirationDatePlain]
      ,[PrimaryAccountNumberCipher]
      ,[PrimaryAccountNumberKeyId]
      ,[NoCVV]
      ,[OriginalOrderId]
      ,[CardAcceptorTerminalIdentification]
      ,[Amount]
      ,[ProcessingOrderId]
      ,[IpAddress]
      ,[CustomerName]
      ,[Phone]
      ,[Email]
      ,[RespCode]
      ,[ApprovalCode]
      ,[ClearingState]
      ,[FileNumber]
  FROM [Payture20].[dbo].[VtbAuthorization]

  */

  INSERT INTO [dbo].[VtbAuthorization](--[Id]
      [Date]
      ,[MerchantContractId]
      ,[MerchantOrderId]
      ,[ExpirationDatePlain]
      ,[PrimaryAccountNumberCipher]
      ,[PrimaryAccountNumberKeyId]
      ,[NoCVV]
      ,[OriginalOrderId]
      ,[CardAcceptorTerminalIdentification]
      ,[Amount]
      ,[ProcessingOrderId]
      ,[IpAddress]
      ,[CustomerName]
      ,[Phone]
      ,[Email]
      ,[RespCode]
      ,[ApprovalCode]
      ,[ClearingState]
      ,[FileNumber])
	VALUES
	  ('2021-02-01 00:00:00.001' --[Date]
      ,2953						--[MerchantContractId]
      ,'000000000000000001'		--[MerchantOrderId]
      ,'1512'						--[ExpirationDatePlain]
      --,'zuXQwwbh0vBwi6KkQmqUI6ZiUE+4sLCIv9Yulkt7z/Y='	--[PrimaryAccountNumberCipher]
	  ,'test'	--[PrimaryAccountNumberCipher]
      ,1							--[PrimaryAccountNumberKeyId]
      ,0							--[NoCVV]
      ,'000000000000000001' --[OriginalOrderId]
      ,20000012					--[CardAcceptorTerminalIdentification]
      ,1						--[Amount]
      ,NULL						--[ProcessingOrderId]
      ,'127.0.0.1'				--[IpAddress]
      ,''						--[CustomerName]
      ,''						--[Phone]
      ,''						--[Email]
      ,NULL						--[RespCode]
      ,'test'					--[ApprovalCode]
      ,NULL						--[ClearingState]
      ,NULL						--[FileNumber]
	  )