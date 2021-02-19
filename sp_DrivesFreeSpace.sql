USE [master]
GO

/****** Object:  StoredProcedure [dbo].[DBA_Free_Space_Report]    Script Date: 07/22/2014 10:31:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Vladimir Aleev
-- Create date: 22 July 2014
-- Description:	Report of free space on all physical disks
-- =============================================
CREATE PROCEDURE [dbo].[DBA_Report_Free_Space]
 
AS
BEGIN
	SET NOCOUNT ON;
	IF object_id('tempdb..#Drives','U') IS NOT NULL DROP TABLE #Drives
	CREATE TABLE #Drives
	(
		Drive VARCHAR(1),
		FreeSpace VARCHAR(50)
	)
	DECLARE @TableHTML_Drives NVARCHAR(MAX)
	DECLARE @Subj NVARCHAR(128)	

	SET @Subj = @@SERVERNAME + ' Report Disk Free Space';
	INSERT INTO #Drives EXEC master..xp_fixeddrives

	IF EXISTS(SELECT * FROM #Drives)
	BEGIN
		SET @TableHTML_Drives =
	    N'<H1>' +@@SERVERNAME+ ' Report: Disks Free Space</H1>' +
		N'<table border="1">' +
		N'<tr><th>Drive Letter</th><th>Free Space, Mb</th>' +
		N'</tr>' +
		CAST(	( SELECT td = Drive,
					'',
					[td/@align] = 'right',
					td = FreeSpace,
                    ''
					FROM #Drives
					FOR XML PATH('tr'), TYPE 
				) AS NVARCHAR(MAX)
			) +
		N'</table>' 
	END;
	IF @TableHTML_Drives <> ''
	BEGIN
		EXEC msdb.dbo.sp_send_dbmail 
				@profile_name = 'DBA_Profile',
				@recipients = 'Oradba@voz.ru',
				@subject = @Subj,
				@body = @TableHTML_Drives,
				@body_format = 'HTML';
	END

	DROP TABLE #Drives;
END

GO


