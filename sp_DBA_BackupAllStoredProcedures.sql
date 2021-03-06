USE [msdb]
GO
/****** Object:  StoredProcedure [dbo].[sp_DBA_BackupAllStoredProcedures]    Script Date: 19.07.2018 12:44:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
/*==========================================================================================    
Name:  Export all stored procedures for all user databases to particular location    
Parameters:   
@ExportDataPath specifies location to where backup of sp needs to store.  eg. ''C:\Backup\StoredProcedure\''   
Returns:      
Description: It creates main folder in @ExportDataPath which contains current 
   date and time, in that folder it creates different folders for each databases and   
creates stored procedure related to database.   
==========================================================================================*/    
    
CREATE PROCEDURE [dbo].[sp_DBA_BackupAllStoredProcedures]
    (
      @ExportDataPath NVARCHAR(1000) = NULL    
    )
AS 
    BEGIN    
        SET QUOTED_IDENTIFIER OFF  
        SET NOCOUNT ON  
        BEGIN TRY  
            DECLARE @ExportPath AS NVARCHAR(1000)  
            SET @ExportPath = @ExportDataPath  
            IF ( ISNULL(@ExportPath, '') = '' ) 
                BEGIN  
                    SET @ExportPath = 'C:\Backup\StoredProcedure\'  
                END  
            SET @ExportPath += ( SELECT CONVERT(VARCHAR(100), GETDATE(), 102) + '_' + REPLACE(CONVERT(VARCHAR(100), GETDATE(), 108),':','.')) + '\'  
            -- variables for first while loop  
            DECLARE @DatabaseName AS NVARCHAR(1000)  
            -- variables for second while loop  
            DECLARE @ExportFilePath NVARCHAR(1000)        
            DECLARE @ServerName NVARCHAR(100)        
            SELECT  @ServerName = CONVERT(SYSNAME, SERVERPROPERTY(N'servername'))     
            DECLARE @GetProcedureNames NVARCHAR(MAX)  
            DROP TABLE IF EXISTS #Databases 
            SELECT  name ,
                    ROW_NUMBER() OVER ( ORDER BY name ) AS RowNum
            INTO    #Databases
            FROM    sys.databases
            WHERE   database_id > 4  
            DECLARE @DatabaseCurrentPosition INT = 1  
            WHILE @DatabaseCurrentPosition <= ( SELECT  COUNT(1)
                                                FROM    #Databases
                                              ) 
                BEGIN  
                    SELECT  @DatabaseName = NAME
                    FROM    #Databases
                    WHERE   RowNum = @DatabaseCurrentPosition  
                    SET @ExportFilePath = @ExportPath + @DatabaseName       
                    EXECUTE master.dbo.xp_create_subdir @ExportFilePath   
                    DROP TABLE IF EXISTS #Procedures   
                    CREATE TABLE #Procedures
                        (
                          RoutineName NVARCHAR(MAX) ,
                          RowNum INT ,
                          ObjectID INT
                        )  
                    SET @GetProcedureNames = N'INSERT INTO #Procedures 
					                         SELECT QUOTENAME(s.[name]) + ''.'' + QUOTENAME(o.[name]) AS RoutineName,
											 ROW_NUMBER() OVER ( ORDER BY s.[name],o.[name]) AS RowNum,sm.object_id as ObjectID 
											 FROM
												' + @DatabaseName + '.sys.objects AS o  
											 INNER JOIN
												' + @DatabaseName + '.sys.schemas AS s 
												ON s.[schema_id] = o.[schema_id] 
											INNER JOIN
												' + @DatabaseName + '.sys.sql_modules sm 
												ON o.[object_id]=sm.[object_id]
											WHERE type IN (''p'',''v'',''fn'') AND o.is_ms_shipped = 0 '
                    EXEC(@GetProcedureNames)
                    IF ( ( SELECT   COUNT(1)
                           FROM     #Procedures
                         ) > 1 ) 
                        BEGIN
                            DECLARE @ProcedureCurrentPosition INT = 1  
                            WHILE @ProcedureCurrentPosition <= ( SELECT
                                                              COUNT(1)
                                                              FROM
                                                              #Procedures
                                                              ) 
                                BEGIN  
                                    DECLARE @ProcedureContent NVARCHAR(MAX)     
                                    DECLARE @ProcedureName NVARCHAR(MAX)   
                                    DECLARE @ObjectID INT
                                    
                                    Select  @ProcedureName = RoutineName ,
                                            @ObjectID = ObjectID
                                    FROM    #Procedures
                                    WHERE   RowNum = @ProcedureCurrentPosition 
                                    SET @ExportFilePath = @ExportPath + @DatabaseName + '\' + @ProcedureName + '.sql'  
                                    DECLARE @Que NVARCHAR(MAX)= 'SELECT Definition FROM ' + @dataBaseName + '.sys.sql_modules sm WHERE sm.[object_id]='+ CAST (@objectID AS NVARCHAR)
                                   DECLARE @sql NVARCHAR(4000)        
                                   SELECT  @sql = 'bcp "' + @Que + '" queryout ' + @ExportFilePath + ' -c -t -T -S ' + ''+ @ServerName + ''
								   --PRINT @sql
								   EXEC xp_cmdshell @sql, no_output 
                                   SET @ProcedureCurrentPosition = @ProcedureCurrentPosition + 1  
                                END    
                        END      
                    SET @DatabaseCurrentPosition = @DatabaseCurrentPosition + 1  
                END     
        END TRY        
        BEGIN CATCH        
   -- Raise an error with the details of the exception   
            DECLARE 
					@ErrMsg NVARCHAR(4000) ,
					@ErrSeverity INT        
            SELECT  @ErrMsg = ERROR_MESSAGE() ,
                    @ErrSeverity = ERROR_SEVERITY()        
            RAISERROR(@ErrMsg, @ErrSeverity,1)        
            RETURN        
        END CATCH ;    
    END
