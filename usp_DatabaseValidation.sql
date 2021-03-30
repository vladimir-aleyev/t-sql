CREATE PROCEDURE [dbo].[usp_DatabaseValidation]
    @TableName varchar(50)

AS
BEGIN

    SET NOCOUNT ON;

    -- parameter = if no table name was passed do them all, otherwise just check the one

    -- create a temp table that lists all tables in target database

    CREATE TABLE #ChkSumTargetTables ([fullname] varchar(250), [name] varchar(50), chksum int);
    INSERT INTO #ChkSumTargetTables ([fullname], [name], [chksum])
        SELECT DISTINCT
            '[MyDatabase].[' + S.name + '].['
            + T.name + ']' AS [fullname],
            T.name AS [name],
            0 AS [chksum]
        FROM MyDatabase.sys.tables T
            INNER JOIN MyDatabase.sys.schemas S ON T.schema_id = S.schema_id
        WHERE 
            T.name like IsNull(@TableName,'%');

    -- create a temp table that lists all tables in source database

    CREATE TABLE #ChkSumSourceTables ([fullname] varchar(250), [name] varchar(50), chksum int)
    INSERT INTO #ChkSumSourceTables ([fullname], [name], [chksum])
        SELECT DISTINCT
            '[MyLinkedServer].[MyDatabase].[' + S.name + '].['
            + T.name + ']' AS [fullname],
            T.name AS [name],
            0 AS [chksum]
        FROM [MyLinkedServer].[MyDatabase].sys.tables T
            INNER JOIN [MyLinkedServer].[MyDatabase].sys.schemas S ON 
            T.schema_id = S.schema_id
        WHERE
            T.name like IsNull(@TableName,'%');;

    -- build a dynamic sql statement to populate temp tables with the checksums of each table

    DECLARE @TargetStmt VARCHAR(MAX)
    SELECT  @TargetStmt = COALESCE(@TargetStmt + ';', '')
            + 'UPDATE #ChkSumTargetTables SET [chksum] = (SELECT CHECKSUM_AGG(BINARY_CHECKSUM(*)) FROM '
            + T.FullName + ') WHERE [name] = ''' + T.Name + ''''
    FROM    #ChkSumTargetTables T

    SELECT  @TargetStmt

    DECLARE @SourceStmt VARCHAR(MAX)
    SELECT  @SourceStmt = COALESCE(@SourceStmt + ';', '')
            + 'UPDATE #ChkSumSourceTables SET [chksum] = (SELECT CHECKSUM_AGG(BINARY_CHECKSUM(*)) FROM '
            + S.FullName + ') WHERE [name] = ''' + S.Name + ''''
    FROM    #ChkSumSourceTables S

    -- execute dynamic statements - populate temp tables with checksums

    EXEC (@TargetStmt);
    EXEC (@SourceStmt);

    --compare the two databases to find any checksums that are different

    SELECT  TT.FullName AS [TABLES WHOSE CHECKSUM DOES NOT MATCH]
    FROM #ChkSumTargetTables TT
    LEFT JOIN #ChkSumSourceTables ST ON TT.Name = ST.Name
    WHERE IsNull(ST.chksum,0) <> IsNull(TT.chksum,0)

    --drop the temp tables from the tempdb

    DROP TABLE #ChkSumTargetTables;
    DROP TABLE #ChkSumSourceTables;

END