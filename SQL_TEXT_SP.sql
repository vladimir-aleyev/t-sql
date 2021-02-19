----------------------------------------------------
--                     1                          --
----------------------------------------------------
select
	prc.name,
	mdl.definition
from
	sys.procedures prc
	join
	sys.sql_modules mdl
	on
	prc.object_id = mdl.object_id
WHERE
definition LIKE '%- çàìåíà íà %'

----------------------------------------------------
--                     2                          --
----------------------------------------------------
SELECT 
	o.type_desc AS ROUTINE_TYPE,
	o.[name] AS ROUTINE_NAME,
	m.definition AS ROUTINE_DEFINITION
FROM
	sys.sql_modules AS m 
	INNER JOIN 
	sys.objects AS o
	ON m.object_id = o.object_id 
WHERE 
	m.definition LIKE '%- çàìåíà íà %'
order by
	ROUTINE_NAME



