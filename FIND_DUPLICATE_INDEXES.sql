WITH IndexSchema AS (
SELECT i.object id
,i.index id
,i.name
,(SELECT CASE key ordinal WHEN 0 THEN NULL ELSE QUOTENAME(column id,'(') END
FROM sys.index columns ic
WHERE ic.object id = i.object id
AND ic.index id = i.index id
ORDER BY key ordinal, column id
FOR XML PATH('')) AS index columns keys
,(SELECT CASE key ordinal WHEN 0 THEN QUOTENAME(column id,';(') ELSE NULL END
FROM sys.index columns ic
WHERE ic.object id = i.object id
AND ic.index id = i.index id
ORDER BY column id
FOR XML PATH('')) AS included columns
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object id = i.object id
WHERE i.type desc IN ('NONCLUSTERED', 'HEAP')
)
SELECT QUOTENAME(DB NAME()) AS database name
,QUOTENAME(OBJECT SCHEMA NAME(is1.object id)) + '.'
+ QUOTENAME(OBJECT NAME(is1.object id)) AS object name
,STUFF((SELECT ', ' + c.name
FROM sys.index columns ic
INNER JOIN sys.columns c ON ic.object id = c.object id AND ic.column id = c.column id
WHERE ic.object id = is1.object id
AND ic.index id = is1.index id
ORDER BY ic.key ordinal, ic.column id
FOR XML PATH('')),1,2,'') AS index columns
,is1.name as index name
,SUM(CASE WHEN is1.index id = h.index id THEN
ISNULL(h.user seeks,0)+ISNULL(h.user scans,0)+ISNULL(h.user lookups,0)+ISNULL(h.user
updates,0) END) index activity
,is2.name as duplicate index name
,SUM(CASE WHEN is2.index id = h.index id THEN
ISNULL(h.user seeks,0)+ISNULL(h.user scans,0)+ISNULL(h.user lookups,0)+ISNULL(h.user
updates,0) END) duplicate index activity
FROM IndexSchema is1
INNER JOIN IndexSchema is2 ON is1.object id = is2.object id
AND is1.index id > is2.index id
AND is1.index columns keys = is2.index columns keys
AND is1.included columns = is2.included columns
LEFT OUTER JOIN IndexingMethod.dbo.index usage stats history h ON is1.object id = h.object id
GROUP BY is1.object id, is1.name, is2.name, is1.index id