----------------------------------------------------------------------------------------------------------------
-- The sample scripts are not supported under any Microsoft standard support 
-- program or service. The sample scripts are provided AS IS without warranty  
-- of any kind. Microsoft further disclaims all implied warranties including,  
-- without limitation, any implied warranties of merchantability or of fitness for 
-- a particular purpose. The entire risk arising out of the use or performance of  
-- the sample scripts and documentation remains with you. In no event shall 
-- Microsoft, its authors, or anyone else involved in the creation, production, or 
-- delivery of the scripts be liable for any damages whatsoever (including, 
-- without limitation, damages for loss of business profits, business interruption, 
-- loss of business information, or other pecuniary loss) arising out of the use 
-- of or inability to use the sample scripts or documentation, even if Microsoft 
-- has been advised of the possibility of such damages 
-----------------------------------------------------------------------------------------------------------------

SET NOCOUNT ON;

DECLARE @tempdbDataFileCount int;
DECLARE @suggestedDataFilecount int;
DECLARE @bSuggestions bit;	-- Check if suggestions.

SET @bSuggestions = 0;

-- checks current number of tempdb data files

SELECT @tempdbDataFileCount = COUNT(*) FROM sys.master_files 
WHERE database_id = DB_ID('tempdb') AND type_desc = 'ROWS';
PRINT N'Count of tempdb data files = ' + CONVERT(nvarchar(10), @tempdbDataFileCount);

-- suggests ideal number of tempdb data files (subject to testing)

SELECT @suggestedDataFilecount = CASE WHEN cpu_count <= 8 THEN cpu_count ELSE 8 END  
FROM sys.dm_os_sys_info;

IF @tempdbDataFileCount <> @suggestedDataFilecount
BEGIN
	SET @bSuggestions = 1;
	PRINT N'Ideal number of tempdb data files = ' 
		+ CONVERT(nvarchar(10), @suggestedDataFilecount)
		+ '. This should ideally be implemented after testing.';
END 

IF @tempdbDataFileCount > 1
BEGIN

	-- checks if tempdb files are created of equal size

	IF (EXISTS(	SELECT	name,
						size,
						physical_name
				FROM	tempdb.sys.database_files
				WHERE	type_desc = 'ROWS'
				AND		size <> (SELECT MAX(size) FROM tempdb.sys.database_files WHERE type_desc = 'ROWS')))
	BEGIN	
		SET @bSuggestions = 1;
		PRINT N'File sizes of tempdb data files do not appear to be equal. '
				  + N'Please verify initial size is same for all tempdb data files.';
	END

	-- checks if tempdb files are created of equal growth (increment and type)

	IF (EXISTS(	SELECT	name,
						growth,
						physical_name
				FROM	tempdb.sys.database_files
				WHERE	type_desc = 'ROWS'
				AND		growth <> (SELECT MAX(growth) FROM tempdb.sys.database_files WHERE type_desc = 'ROWS'))
				
		OR EXISTS(
				SELECT	name,
						is_percent_growth,
						physical_name
				FROM	tempdb.sys.database_files
				WHERE	type_desc = 'ROWS'
				AND		is_percent_growth <> (SELECT TOP 1 is_percent_growth FROM tempdb.sys.database_files WHERE type_desc = 'ROWS')
				))
	BEGIN	
		SET @bSuggestions = 1;
		PRINT N'File growth of tempdb data files do not appear to be same. '
				  + N'Please verify growth is same for all tempdb data files.';
	END

	-- checks if tempdb trace flag (for uniform extent allocation) is enabled and required depending on Sql version 

  --  DECLARE @dbccstatus table
  --  (
  --          TraceFlag     int,
  --          Status        int,
  --          Global        int,
  --          Session              int
  --  )
  --  INSERT INTO @dbccstatus EXEC(N'dbcc tracestatus(1118) with no_infomsgs')
  --  IF NOT EXISTS(SELECT * FROM @dbccstatus WHERE TraceFlag = 1118 AND Global = 1)
  --  BEGIN
		--SET @bSuggestions = 1;
  --      PRINT N'Trace flag 1118 is suggested however is not operational.';
  --  END

END

-- suggests tempdb configuration is healthy if no suggestions were made

IF @bSuggestions = 0
BEGIN
	PRINT N'Tempdb configuration appears healthy.';
END

