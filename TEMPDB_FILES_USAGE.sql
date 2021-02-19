SELECT
	db_name(saf.dbid)        as [База данных]
   ,saf.name                 as [Логическое имя]
   ,vfs.BytesRead/1048576    as [Прочитано (Мб)]
   ,vfs.BytesWritten/1048576 as [Записано (Мб)]
   ,saf.filename             as [Путь к файлу]
FROM
	master..sysaltfiles              as saf
	join
	::fn_virtualfilestats(NULL,NULL) as vfs ON vfs.dbid = saf.dbid AND
                                                  vfs.fileid = saf.fileid 
												  AND
                                                  saf.dbid NOT IN (1,3,4)
  where (
        vfs.BytesRead/1048576 <> 0 
     or vfs.BytesWritten/1048576 <> 0
        )
    and saf.dbid = db_id('tempdb')
  order by 
    vfs.BytesRead/1048576 + BytesWritten/1048576 desc
