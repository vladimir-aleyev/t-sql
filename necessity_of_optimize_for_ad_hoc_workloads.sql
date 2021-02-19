IF EXISTS (
        -- this is for 2008 and up
        SELECT 1
        FROM sys.configurations
        WHERE NAME = 'optimize for ad hoc workloads'
        )
BEGIN
    DECLARE @AdHocSizeInMB DECIMAL(14, 2)
        ,@TotalSizeInMB DECIMAL(14, 2)
        ,@ObjType NVARCHAR(34)

    SELECT @AdHocSizeInMB = SUM(CAST((
                    CASE 
                        WHEN usecounts = 1
                            AND LOWER(objtype) = 'adhoc'
                            THEN size_in_bytes
                        ELSE 0
                        END
                    ) AS DECIMAL(14, 2))) / 1048576
        ,@TotalSizeInMB = SUM(CAST(size_in_bytes AS DECIMAL(14, 2))) / 1048576
    FROM sys.dm_exec_cached_plans

    SELECT 'SQL Server Configuration' AS GROUP_TYPE
        ,' Total cache plan size (MB): ' + cast(@TotalSizeInMB AS VARCHAR(max)) + '. Current memory occupied by adhoc plans only used once (MB):' + cast(@AdHocSizeInMB AS VARCHAR(max)) + '.  Percentage of total cache plan occupied by adhoc plans only used once :' + cast(CAST((@AdHocSizeInMB / @TotalSizeInMB) * 100 AS DECIMAL(14, 2)) AS VARCHAR(max)) + '%' + ' ' AS COMMENTS
        ,' ' + CASE 
            WHEN @AdHocSizeInMB > 200
                OR ((@AdHocSizeInMB / @TotalSizeInMB) * 100) > 25 -- 200MB or > 25%
                THEN 'Switch on Optimize for ad hoc workloads as it will make a significant difference. Ref: http://sqlserverperformance.idera.com/memory/optimize-ad-hoc-workloads-option-sql-server-2008/. http://www.sqlskills.com/blogs/kimberly/post/procedure-cache-and-optimizing-for-adhoc-workloads.aspx'
            ELSE 'Setting Optimize for ad hoc workloads will make little difference !!'
            END + ' ' AS RECOMMENDATIONS
END