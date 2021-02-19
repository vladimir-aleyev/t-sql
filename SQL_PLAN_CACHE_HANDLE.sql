--1--
SELECT TOP 20
	cp.cacheobjtype,
	cp.objtype,
	cp.plan_handle,
	t.text
FROM
	sys.dm_exec_cached_plans cp
	CROSS APPLY
	sys.dm_exec_sql_text(cp.plan_handle) t
WHERE
	t.text LIKE '%cross_analysis_by_masks_sp%'
	AND
	t.dbid = DB_ID('autodoc')


--2--
SELECT TOP(100)
	q.TEXT,
	cp.usecounts,
	cp.objtype,
	p.*,
	q.*,
	cp.plan_handle
	,
	cp.*
FROM
	sys.dm_exec_cached_plans cp
	CROSS apply
	sys.dm_exec_query_plan(cp.plan_handle) p
	CROSS apply
	sys.dm_exec_sql_text(cp.plan_handle) AS q
WHERE
	--cp.cacheobjtype = 'Compiled Plan'
	--AND
	p.objectid = 1737681884
	AND
	q.TEXT  LIKE '%cross_analysis_by_masks_sp%'  --import_ocl_proc
	AND
	q.TEXT  NOT LIKE '%sys.dm_exec_cached_plans %'
GO



SELECT qs.plan_handle, a.attrlist,
		qs.*,
		est.text,

		CASE qs.[statement_end_offset]  
           WHEN -1 THEN  
              --The end of the full command is also the end of the active statement 
              SUBSTRING(est.TEXT, (qs.[statement_start_offset]/2) + 1, 2147483647) 
           ELSE   
              --The end of the active statement is not at the end of the full command 
              SUBSTRING(est.TEXT, (qs.[statement_start_offset]/2) + 1, (qs.[statement_end_offset] - qs.[statement_start_offset])/2)   
        END  AS sql_command
FROM   sys.dm_exec_query_stats qs
CROSS  APPLY sys.dm_exec_sql_text(qs.sql_handle) est
CROSS  APPLY (SELECT epa.attribute + '=' + convert(nvarchar(127), epa.value) + '   '
              FROM   sys.dm_exec_plan_attributes(qs.plan_handle) epa
              WHERE  epa.is_cache_key = 1
              ORDER  BY epa.attribute
              FOR    XML PATH('')) AS a(attrlist)
WHERE  est.objectid = object_id ('clients_log_proc')
  AND  est.dbid     = db_id('autodoc')



--DBCC FREEPROCCACHE(0x05000A00424E6416307DC9486E01000001000000000000000000000000000000000000000000000000000000)
--DBCC FREEPROCCACHE(0x05000A00424E641640D3FDFB6A01000001000000000000000000000000000000000000000000000000000000)
--DBCC FREEPROCCACHE(0x05000A00424E6416505E89C35D01000001000000000000000000000000000000000000000000000000000000)
--SELECT * FROM sys.dm_exec_query_plan(0x05000A00DCEB92671018FDCDAB01000001000000000000000000000000000000000000000000000000000000);
--SELECT * FROM sys.dm_exec_query_plan(0x05000A00DCEB92671018FDCDAB01000001000000000000000000000000000000000000000000000000000000);