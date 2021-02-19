SELECT * FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(sql_handle)
CROSS APPLY sys.dm_exec_text_query_plan(qs.plan_handle, qs.statement_start_offset, qs.statement_end_offset) AS qp
WHERE text LIKE N'%TECDOC_GetArtAppl_NNN_sp%';
GO

-- Create plan guides for the first and third statements in the batch by specifying the statement offsets.
BEGIN TRANSACTION

DECLARE @plan_handle varbinary(64) = 0x0500090054C89A4840D266996F02000001000000000000000000000000000000000000000000000000000000;
DECLARE @offset int = 4794

SELECT 
	--@plan_handle = 
	plan_handle, 
	--@offset = 
	qs.statement_start_offset
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS st
CROSS APPLY sys.dm_exec_text_query_plan(qs.plan_handle, qs.statement_start_offset, qs.statement_end_offset) AS qp
WHERE text LIKE N'%TECDOC_GetArtAppl_NNN_sp%'
AND SUBSTRING(st.text, (qs.statement_start_offset/2) + 1,
                        ((CASE statement_end_offset 
                              WHEN -1 THEN DATALENGTH(st.text)
                              ELSE qs.statement_end_offset END 
                              - qs.statement_start_offset)/2) + 1)  like '%insert into @filter(art_id,sup_id)%'

EXECUTE sp_create_plan_guide_from_handle 
    @name =  N'Plan_Guide_for_TECDOC_GetArtAppl_NNN_sp',
    @plan_handle = 0x0500090054C89A4840D266996F02000001000000000000000000000000000000000000000000000000000000,
    @statement_start_offset = 4794;


COMMIT TRANSACTION
GO

-- Verify the plan guides are created.
SELECT * FROM sys.plan_guides;
GO