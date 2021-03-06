USE [msdb]
GO
/****** Object:  StoredProcedure [dbo].[sp_DBA_robocopy]    Script Date: 30.05.2019 17:16:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_DBA_robocopy]
    @source_path VARCHAR(128),
    @destination_path VARCHAR(128),
	@file VARCHAR(128) = '*.*',
	@log VARCHAR(128) = 'c:\copy_files.log'
AS
	SET NOCOUNT ON
	DECLARE @cmd VARCHAR(500)
	DECLARE @ret INT
	SET @cmd = 'ROBOCOPY.EXE ' + @source_path + ' ' + @destination_path + ' ' + @file + ' /R:3 /W:3 /MIR /NP /LOG:' + @log
	EXECUTE @ret = master.sys.xp_cmdshell @cmd
	  
RETURN @ret

 
