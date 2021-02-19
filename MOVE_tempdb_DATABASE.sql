/*
Перемещение базы данных tempdb.
В следующем примере показано перемещение файлов базы данных tempdb и журнала на новое место в рамках запланированного перемещения.
*/

/*
Примечание:
Так как база данных tempdb заново создается при каждом запуске службы SQL Server,
физически перемещать файлы данных и журналов не нужно.
Файлы создаются в новом месте во время перезагрузки службы на шаге 3. 
До перезагрузки службы база данных tempdb продолжает использовать файлы данных и журналов в прежнем расположении. 
После перезапуска службы SQL Server может потребоваться удалить старые файлы данных и журналов tempdb из исходного расположения.
*/

/*
As a general rule, if the number of logical processors is less than or equal to 8,
use the same number of data files as logical processors.
If the number of logical processors is greater than 8, use 8 data files and then if contention continues,
increase the number of data files by multiples of 4 (up to the number of logical processors) 
until the contention is reduced to acceptable levels or make changes to the workload/code.
https://support.microsoft.com/en-us/kb/2154845
*/

--	1.	Определение логических имен файлов базы данных tempdb и их текущего местоположения на диске.

	SELECT name, physical_name AS CurrentLocation
	FROM sys.master_files
	WHERE database_id = DB_ID(N'tempdb');
	GO

--	2.	Измените местоположение каждого файла с помощью инструкции ALTER DATABASE.

	USE master;
	GO
	ALTER DATABASE tempdb 
	MODIFY FILE (NAME = tempdev, FILENAME = 'E:\SQLData\tempdb.mdf');
	GO
	ALTER DATABASE tempdb 
	MODIFY FILE (NAME = templog, FILENAME = 'F:\SQLLog\templog.ldf');
	GO

--	3.	Остановите и перезапустите экземпляр SQL Server.

--	4.	Проверьте изменение файла.
	
	SELECT name, physical_name AS CurrentLocation, state_desc
	FROM sys.master_files
	WHERE database_id = DB_ID(N'tempdb');
	
--	5.	Удалите файлы tempdb.mdf и templog.ldf из начального местоположения.