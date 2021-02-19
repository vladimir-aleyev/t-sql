SELECT @@version AS [FULL Version Info];
---
SELECT SERVERPROPERTY('BuildClrVersion') AS BuildClrVersion	--Версия среды CLR Microsoft .NET Framework, которая использовалась при сборке экземпляра SQL Server. NULL = недопустимый ввод, ошибка или неприменимо. Базовый тип данных: nvarchar(128)
SELECT SERVERPROPERTY('Collation') AS Collation		 	--Имя параметров сортировки для сервера, установленного по умолчанию. NULL = недопустимый ввод или произошла ошибка. Базовый тип данных: nvarchar(128)
SELECT SERVERPROPERTY('CollationID') AS CollationID		--Идентификатор параметров сортировки SQL Server. Базовый тип данных: int
SELECT SERVERPROPERTY('ComparisonStyle') AS ComparisonStyle	--Стиль сравнения Windows для параметров сортировки.Базовый тип данных: int
SELECT SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS ComputerNamePhysicalNetBIOS	--Имя NetBIOS для локального компьютера, на котором работает экземпляр SQL Server.
														--Для кластеризованного экземпляра SQL Server на отказоустойчивом кластере это значение изменяется, когда экземпляр SQL Server переключается на другие узлы в отказоустойчивом кластере.
														--Для изолированного экземпляра SQL Server это значение остается постоянным и совпадает со значением, возвращаемым свойством MachineName.
														--Примечание. Если экземпляр SQL Server находится в отказоустойчивом кластере и необходимо получить имя экземпляра отказоустойчивого кластера, воспользуйтесь свойством MachineName.
														--NULL = недопустимый ввод, ошибка или неприменимо. Базовый тип данных: nvarchar(128)
SELECT SERVERPROPERTY('Edition') AS Edition			--Установленный выпуск экземпляра SQL Server. Используйте значение этого свойства для определения функций и ограничений, таких как ограничения вычислительной емкости для разных выпусков SQL Server. В 64-разрядных версиях компонента Компонент Database Engine к обозначению версии добавляется «(64-разрядная версия)».

											--Возвращает:
											--«Enterprise Edition»;
											--"Enterprise Edition": лицензирование по числу ядер;
											--выпуск «Enterprise Evaluation Edition»;
											--выпуск «Business Intelligence»;
											--выпуск «Developer Edition»;
											--выпуск «Express Edition»;
											--экспресс-выпуск с дополнительными службами;
											--выпуск «Standard Edition»;
											--«Web Edition».
											--"SQL Azure" означает База данных SQL или Хранилище данных SQL.
											--Базовый тип данных: nvarchar(128)

SELECT SERVERPROPERTY('EditionID') EditionID			--EditionID представляет установленный выпуск продукта для экземпляра SQL Server. Используйте значение этого свойства для определения функций и ограничений, таких как ограничения вычислительной емкости для разных выпусков SQL Server.

											--	1804890536 = Enterprise
											--	1872460670 = Enterprise Edition: лицензирование по числу ядер
											--	610778273 = Enterprise Evaluation
											--	284895786 = Business Intelligence
											--	-2117995310 = Developer
											--	-1592396055 = Express
											--	-133711905= Express with Advanced Services
											--	-1534726760 = Standard
											--	1293598313 = Web
											--	1674378470 = база данных SQL или хранилище данных SQL
											--	Базовый тип данных: bigint

SELECT SERVERPROPERTY('EngineEdition') EngineEdition		--	Выпуск компонента Компонент Database Engine для экземпляра SQL Server, установленного на сервере.

											--	1 = Personal или Desktop Engine (недоступен для SQL Server 2005 и более поздних версий).
											--	2 = Standard (возвращается для выпусков Standard, Web и Business Intelligence).
											--	3 = Enterprise (это значение возвращается для выпусков Evaluation Edition, Developer Edition и обоих вариантов Enterprise Edition).
											--	4 = Express (возвращается для выпусков Express, Express with Tools и Express with Advanced Services).
											--	5 = База данных SQL
											--	6 – Хранилище данных SQL
											--	8 = управляемый экземпляр
											--	Базовый тип данных: int

SELECT SERVERPROPERTY('HadrManagerStatus') HadrManagerStatus	--Применимо к: с SQL Server 2012 (11.x) до SQL Server 2017.

											--Показывает, запущен ли диспетчер Группы доступности AlwaysOn.
											--	0 = не запущен, ожидает связи.
											--	1 = запущен и выполняется.
											--	2 = не запущен и завершился неудачно.
											--	NULL = недопустимый ввод, ошибка или неприменимо.

SELECT SERVERPROPERTY('InstanceDefaultDataPath') InstanceDefaultDataPath	-- from SQL Server 2012 (11.x).Имя пути по умолчанию к файлам данных экземпляра.
SELECT SERVERPROPERTY('InstanceDefaultLogPath') InstanceDefaultLogPath		-- from SQL Server 2012 (11.x).Имя пути по умолчанию к файлам журналов экземпляра.

SELECT SERVERPROPERTY('InstanceName') InstanceName				--Имя экземпляра, к которому подключен пользователь.Возвращает значение NULL в случае, если имя экземпляра установлено по умолчанию, при возникновении ошибки и в случае, если входные данные оказываются недопустимы.
													--NULL = недопустимый ввод, ошибка или неприменимо. Базовый тип данных: nvarchar(128)

SELECT SERVERPROPERTY('IsAdvancedAnalyticsInstalled') IsAdvancedAnalyticsInstalled	--Возвращает значение 1, если компонент расширенной аналитики был установлен во время установки системы, или значение 0, если компонент расширенной аналитики не был установлен.

SELECT SERVERPROPERTY('IsClustered') IsClustered	 		--Экземпляр сервера настроен для работы в отказоустойчивом кластере.
												--1 = в кластере.
												--0 = не в кластере.
												--NULL = недопустимый ввод, ошибка или неприменимо.Базовый тип данных: int

SELECT SERVERPROPERTY('IsFullTextInstalled') IsFullTextInstalled	--На текущем экземпляре SQL Server установлены компоненты полнотекстового и семантического индексирования.
												--1 = компоненты полнотекстового и семантического индексирования установлены.
												--0 = компоненты полнотекстового и семантического индексирования не установлены.
												--NULL = недопустимый ввод, ошибка или неприменимо.Базовый тип данных: int

SELECT SERVERPROPERTY('IsHadrEnabled') IsHadrEnabled			--Применимо к: с SQL Server 2012 (11.x) до SQL Server 2017.
												--Служба Группы доступности AlwaysOn включена на этом экземпляре сервера.
												--0 = компонент Группы доступности AlwaysOn отключен.
												--1 = компонент Группы доступности AlwaysOn включен.
												--NULL = недопустимый ввод, ошибка или неприменимо.Базовый тип данных: int
												--Для реплик доступности, создаваемых и запускаемых на экземпляре SQL Server, на экземпляре сервера должна быть включена служба Группы доступности AlwaysOn. Дополнительные сведения см. в статье Включение и отключение групп доступности AlwaysOn (SQL Server).
												--Примечание. Свойство IsHadrEnabled относится только к Группы доступности AlwaysOn. Другие возможности высокого уровня доступности или аварийного восстановления, такие как зеркальное отображение базы данных или доставка журналов, не затрагиваются этим свойством сервера.

SELECT SERVERPROPERTY('IsIntegratedSecurityOnly') IsIntegratedSecurityOnly		--Сервер запущен во встроенном режиме безопасности.

														--1 = встроенная безопасность (проверка подлинности Windows)
														--0 = без встроенного режима безопасности. (Как проверка подлинности Windows, так и проверки подлинности SQL Server.)
														--NULL = недопустимый ввод, ошибка или неприменимо.Базовый тип данных: int

SELECT SERVERPROPERTY('IsLocalDB') IsLocalDB				--Применимо к: с SQL Server 2012 (11.x) до SQL Server 2017.Сервер является экземпляром SQL Server Express LocalDB.NULL = недопустимый ввод, ошибка или неприменимо.
SELECT SERVERPROPERTY('IsPolybaseInstalled') IsPolybaseInstalled	--Применимо к: SQL Server 2017.

												--Возвращает значение, показывающее, установлен ли компонент PolyBase в экземпляре сервера.
												--0 = компонент PolyBase не установлен.
												--1 = компонент PolyBase установлен.
												--Базовый тип данных: int

SELECT SERVERPROPERTY('IsSingleUser') IsSingleUser			--Server запущен в однопользовательском режиме.
												--1 = однопользовательский режим.
												--0 = не однопользовательский режим.
												--NULL = недопустимый ввод, ошибка или неприменимо.Базовый тип данных: int

SELECT SERVERPROPERTY('IsXTPSupported') IsXTPSupported			--Применимо к: SQL Server (с SQL Server 2014 (12.x) до SQL Server 2017), База данных SQL.
												--Сервер поддерживает компонент In-Memory OLTP.
												--1 = сервер поддерживает компонент In-Memory OLTP.
												--0= сервер не поддерживает компонент In-Memory OLTP.
												--NULL = недопустимый ввод, ошибка или неприменимо.Базовый тип данных: int

SELECT SERVERPROPERTY('LCID') [Windows locale identifier LCID]			--	Код локали Windows для параметров сортировки.Базовый тип данных: int
SELECT SERVERPROPERTY('LicenseType') LicenseType	--	Не используется. В продукте SQL Server не сохраняются сведения о лицензии. Всегда возвращает DISABLED.Базовый тип данных: nvarchar(128)
SELECT SERVERPROPERTY('MachineName') MachineName	--	Имя компьютера Windows, на котором запущен экземпляр сервера.
										--	Для кластеризованного экземпляра SQL Server, работающего на виртуальном сервере службы кластеров (Майкрософт), возвращается имя виртуального сервера.
										--	NULL = недопустимый ввод, ошибка или неприменимо.Базовый тип данных: nvarchar(128)
SELECT SERVERPROPERTY('NumLicenses') NumLicenses	--	Не используется. В продукте SQL Server не сохраняются сведения о лицензии. Всегда возвращает значение NULL.Базовый тип данных: int
SELECT SERVERPROPERTY('ProcessID') ProcessID		--	Идентификатор процесса службы SQL Server. С помощью свойства ProcessID удобно определять, какой файл Sqlservr.exe принадлежит этому экземпляру.Базовый тип данных: int
SELECT SERVERPROPERTY('ProductBuild') ProductBuild	--	Применимо к: SQL Server 2014 (12.x) начиная с октября 2015 г. Номер сборки.
SELECT SERVERPROPERTY('ProductBuildType') ProductBuildType	-- Применимо к: с SQL Server 2012 (11.x) до текущей версии в обновлениях, выпущенных начиная с конца 2015 г. Тип текущей сборки.
											--Возвращает одно из следующих значений.
											--OD = выпуск по запросу для определенного клиента.
											--GDR = выпуск для общего распространения посредством обновления Windows.
											--NULL = неприменимо.
SELECT SERVERPROPERTY('ProductLevel') ProductLevel	--Уровень версии экземпляра SQL Server.
										--Возвращает одно из следующих значений.
										--'RTM' = Исходная выпущенная версия
										--'SPn' = версия пакета обновления
										--'CTPn', = ознакомительная версия для сообщества
										--Базовый тип данных: nvarchar(128)
SELECT SERVERPROPERTY('ProductMajorVersion') ProductMajorVersion	--Применимо к: с SQL Server 2012 (11.x) до текущей версии в обновлениях, выпущенных начиная с конца 2015 г. Основная версия.

SELECT SERVERPROPERTY('ProductMinorVersion') ProductMinorVersion	--Применимо к: с SQL Server 2012 (11.x) до текущей версии в обновлениях, выпущенных начиная с конца 2015 г.Дополнительная версия.

SELECT SERVERPROPERTY('ProductUpdateLevel') ProductUpdateLevel		--Применимо к: с SQL Server 2012 (11.x) до текущей версии в обновлениях, выпущенных начиная с конца 2015 г. Уровень обновления текущей сборки. CU означает накопительный пакет обновления.
												--Возвращает одно из следующих значений.
												--CUn = накопительный пакет обновления
												--NULL= неприменимо.

SELECT SERVERPROPERTY('ProductUpdateReference') ProductUpdateReference	--Применимо к: с SQL Server 2012 (11.x) до текущей версии в обновлениях, выпущенных начиная с конца 2015 г.Статья базы знаний для этого выпуска.
SELECT SERVERPROPERTY('ProductVersion')	ProductVersion		--Версия экземпляра SQL Server в формате основной_номер.дополнительный_номер.сборка.редакция.Базовый тип данных: nvarchar(128)
SELECT SERVERPROPERTY('ResourceLastUpdateDateTime') ResourceLastUpdateDateTime	--	Отображаются дата и время последнего изменения базы данных Resource. Базовый тип данных: datetime
SELECT SERVERPROPERTY('ResourceVersion') ResourceVersion		--Возвращает версию базы данных Resource.Базовый тип данных: nvarchar(128)
SELECT SERVERPROPERTY('ServerName') ServerName			--Сведения об экземпляре и сервере Windows, связанные с определенным экземпляром SQL Server.NULL = недопустимый ввод или произошла ошибка.Базовый тип данных: nvarchar(128)
SELECT SERVERPROPERTY('SqlCharSet')	SqlCharSet	--Идентификатор кодировки SQL из идентификатора параметров сортировки. Базовый тип данных: tinyint
SELECT SERVERPROPERTY('SqlCharSetName') SqlCharSetName	--Имя кодировки SQL из параметров сортировки.Базовый тип данных: nvarchar(128)
SELECT SERVERPROPERTY('SqlSortOrder') SqlSortOrder	--Идентификатор порядка сортировки SQL из параметров сортировки.Базовый тип данных: tinyint
SELECT SERVERPROPERTY('SqlSortOrderName') SqlSortOrderName	--Имя порядка сортировки SQL из параметров сортировки.Базовый тип данных: nvarchar(128)
SELECT SERVERPROPERTY('FilestreamShareName') FilestreamShareName	--Имя общего ресурса, используемое FILESTREAM.
SELECT SERVERPROPERTY('FilestreamConfiguredLevel') FilestreamConfiguredLevel	--Настроенный уровень доступа FILESTREAM. Дополнительные сведения см. в разделе Уровень доступа к файловому потоку.
SELECT SERVERPROPERTY('FilestreamEffectiveLevel') FilestreamEffectiveLevel	--Действующий уровень доступа FILESTREAM. Это значение может отличаться от значения FilestreamConfiguredLevel, если уровень был изменен и ожидается перезапуск экземпляра или перезагрузка компьютера. Дополнительные сведения см. в разделе Уровень доступа к файловому потоку.
---