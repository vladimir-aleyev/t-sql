SELECT TOP 10 
	cp.cacheobjtype,
	cp.objtype,
	cp.plan_handle,
	t.text
FROM
	sys.dm_exec_cached_plans cp
	CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) t
WHERE
	t.text LIKE '%cl_represent_statistics_proc%'
	AND
	t.dbid = DB_ID('database')


