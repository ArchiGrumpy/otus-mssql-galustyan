/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters;

/*
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

-- OPENXML
DECLARE @xmlDocument XML;

-- Считываем XML-файл в переменную
SELECT @xmlDocument = BulkColumn
FROM OPENROWSET
(BULK 'C:\Users\user\Desktop\HW\HW10 - XML_JSON\StockItems.xml', 
 SINGLE_CLOB)
AS data;

-- Проверяем, что в @xmlDocument
SELECT @xmlDocument AS [@xmlDocument];

DECLARE @docHandle INT;
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument;

-- Проверяем, что в docHandle
SELECT @docHandle AS docHandle;

-- Проверяем выборку
SELECT *
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
	[StockItemName] NVARCHAR(100)  '@Name',
	[SupplierID] INT 'SupplierID',
	[UnitPackageID] INT 'Package/UnitPackageID',
	[OuterPackageID] INT 'Package/OuterPackageID',
	[QuantityPerOuter] INT 'Package/QuantityPerOuter',
	[TypicalWeightPerUnit] DECIMAL (18,3) 'Package/TypicalWeightPerUnit',
	[LeadTimeDays] int 'LeadTimeDays',
	[IsChillerStock] bit  'IsChillerStock',
	[TaxRate] DECIMAL (18,3) 'TaxRate',
	[UnitPrice] DECIMAL (18,2) 'UnitPrice'
	);

-- Загружаем эти данные в таблицу Warehouse.StockItems: 
-- существующие записи в таблице обновляем, отсутствующие добавляем (сопоставляем записи по полю StockItemName).
MERGE Warehouse.StockItems  AS target 
	USING (	SELECT *
			FROM OPENXML(@docHandle, N'/StockItems/Item')
			WITH ( 
				[StockItemName] NVARCHAR(100)  '@Name',
				[SupplierID] INT 'SupplierID',
				[UnitPackageID] INT 'Package/UnitPackageID',
				[OuterPackageID] INT 'Package/OuterPackageID',
				[QuantityPerOuter] INT 'Package/QuantityPerOuter',
				[TypicalWeightPerUnit] DECIMAL (18,3) 'Package/TypicalWeightPerUnit',
				[LeadTimeDays] int 'LeadTimeDays',
				[IsChillerStock] bit  'IsChillerStock',
				[TaxRate] DECIMAL (18,3) 'TaxRate',
				[UnitPrice] DECIMAL (18,2) 'UnitPrice'
				)
		) 
		AS source (	[StockItemName],
					[SupplierID],
					[UnitPackageID],
					[OuterPackageID],
					[QuantityPerOuter],
					[TypicalWeightPerUnit],
					[LeadTimeDays],
					[IsChillerStock],
					[TaxRate],
					[UnitPrice] 
					)
		ON
	 (target.[StockItemName] = source.[StockItemName]) 
	WHEN MATCHED 
		THEN UPDATE SET [SupplierID]			= source.[SupplierID] ,
						[UnitPackageID]			= source.[UnitPackageID],
						[OuterPackageID]		= source.[OuterPackageID],
						[QuantityPerOuter]		= source.[QuantityPerOuter],
						[TypicalWeightPerUnit]	= source.[TypicalWeightPerUnit],
						[LeadTimeDays]			= source.[LeadTimeDays],
						[IsChillerStock]		= source.[IsChillerStock],
						[TaxRate]				= source.[TaxRate],
						[UnitPrice]				= source.[UnitPrice]
	WHEN NOT MATCHED 
		THEN INSERT (	[StockItemName],
						[SupplierID],
						[UnitPackageID],
						[OuterPackageID],
						[QuantityPerOuter],
						[TypicalWeightPerUnit],
						[LeadTimeDays],
						[IsChillerStock],
						[TaxRate],
						[UnitPrice],
						LastEditedBy -- в файле эти данных, но поле NOT NULL, поэтому заполняем хоть и нет данных в xml
					) 
			VALUES (	source.[StockItemName],
						source.[SupplierID],
						source.[UnitPackageID],
						source.[OuterPackageID],
						source.[QuantityPerOuter],
						source.[TypicalWeightPerUnit],
						source.[LeadTimeDays],
						source.[IsChillerStock],
						source.[TaxRate],
						source.[UnitPrice],
						1) 
	OUTPUT deleted.*, $action, inserted.*;

-- Надо удалить handle
EXEC sp_xml_removedocument @docHandle;

-- XQuery
DECLARE @x XML;

-- Считываем XML-файл в переменную
SET @x = ( 
  SELECT * FROM OPENROWSET
  (BULK 'C:\Users\user\Desktop\HW\HW10 - XML_JSON\StockItems.xml',
   SINGLE_CLOB) AS d);

-- Проверяем, что в @x
SELECT @x

-- Проверяем выборку
SELECT  
  t.I.value('(@Name)[1]', 'VARCHAR(100)') AS [StockItemName],
  t.I.value('(SupplierID)[1]', 'int') AS [SupplierID],
  t.I.value('(Package/UnitPackageID)[1]', 'int') AS [UnitPackageID],
  t.I.value('(Package/OuterPackageID)[1]', 'int') AS [OuterPackageID],
  t.I.value('(Package/QuantityPerOuter)[1]', 'int') AS [QuantityPerOuter],
  t.I.value('(Package/TypicalWeightPerUnit)[1]', 'DECIMAL (18,3)') AS [TypicalWeightPerUnit],
  t.I.value('(LeadTimeDays)[1]', 'int') AS [LeadTimeDays],
  t.I.value('(IsChillerStock)[1]', 'bit') AS [IsChillerStock],
  t.I.value('(TaxRate)[1]', 'DECIMAL (18,3)') AS [TaxRate],
  t.I.value('(UnitPrice)[1]', 'DECIMAL (18,2)') AS [UnitPrice]
FROM @x.nodes('/StockItems/Item') AS t(I);

-- Загружаем эти данные в таблицу Warehouse.StockItems: 
-- существующие записи в таблице обновляем, отсутствующие добавляем (сопоставляем записи по полю StockItemName).
MERGE Warehouse.StockItems  AS target 
	USING (	SELECT  
			  t.I.value('(@Name)[1]', 'VARCHAR(100)') AS [StockItemName],
			  t.I.value('(SupplierID)[1]', 'int') AS [SupplierID],
			  t.I.value('(Package/UnitPackageID)[1]', 'int') AS [UnitPackageID],
			  t.I.value('(Package/OuterPackageID)[1]', 'int') AS [OuterPackageID],
			  t.I.value('(Package/QuantityPerOuter)[1]', 'int') AS [QuantityPerOuter],
			  t.I.value('(Package/TypicalWeightPerUnit)[1]', 'DECIMAL (18,3)') AS [TypicalWeightPerUnit],
			  t.I.value('(LeadTimeDays)[1]', 'int') AS [LeadTimeDays],
			  t.I.value('(IsChillerStock)[1]', 'bit') AS [IsChillerStock],
			  t.I.value('(TaxRate)[1]', 'DECIMAL (18,3)') AS [TaxRate],
			  t.I.value('(UnitPrice)[1]', 'DECIMAL (18,2)') AS [UnitPrice]
			FROM @x.nodes('/StockItems/Item') AS t(I)
		) 
		AS source (	[StockItemName],
					[SupplierID],
					[UnitPackageID],
					[OuterPackageID],
					[QuantityPerOuter],
					[TypicalWeightPerUnit],
					[LeadTimeDays],
					[IsChillerStock],
					[TaxRate],
					[UnitPrice] 
					)
		ON
	 (target.[StockItemName] = source.[StockItemName]) 
	WHEN MATCHED 
		THEN UPDATE SET [SupplierID]			= source.[SupplierID] ,
						[UnitPackageID]			= source.[UnitPackageID],
						[OuterPackageID]		= source.[OuterPackageID],
						[QuantityPerOuter]		= source.[QuantityPerOuter],
						[TypicalWeightPerUnit]	= source.[TypicalWeightPerUnit],
						[LeadTimeDays]			= source.[LeadTimeDays],
						[IsChillerStock]		= source.[IsChillerStock],
						[TaxRate]				= source.[TaxRate],
						[UnitPrice]				= source.[UnitPrice]
	WHEN NOT MATCHED 
		THEN INSERT (	[StockItemName],
						[SupplierID],
						[UnitPackageID],
						[OuterPackageID],
						[QuantityPerOuter],
						[TypicalWeightPerUnit],
						[LeadTimeDays],
						[IsChillerStock],
						[TaxRate],
						[UnitPrice],
						LastEditedBy -- в файле эти данных, но поле NOT NULL, поэтому заполняем хоть и нет данных в xml
					) 
			VALUES (	source.[StockItemName],
						source.[SupplierID],
						source.[UnitPackageID],
						source.[OuterPackageID],
						source.[QuantityPerOuter],
						source.[TypicalWeightPerUnit],
						source.[LeadTimeDays],
						source.[IsChillerStock],
						source.[TaxRate],
						source.[UnitPrice],
						1) 
	OUTPUT deleted.*, $action, inserted.*;

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

-- Проверяем выборку
SELECT 
    [StockItemName] AS [@Name],
    [SupplierID] AS [SupplierID],
    [UnitPackageID] AS [Package/UnitPackageID],
    [OuterPackageID] AS [Package/OuterPackageID],
    [QuantityPerOuter] AS [Package/QuantityPerOuter],
    [TypicalWeightPerUnit] AS [Package/TypicalWeightPerUnit],
    [LeadTimeDays] AS [LeadTimeDays],
    [IsChillerStock] AS [IsChillerStock],
    [TaxRate] AS [TaxRate],
	[UnitPrice] AS [UnitPrice]
FROM Warehouse.StockItems as i
FOR XML PATH('Item'), ROOT('StockItems') , TYPE;
GO

-- Выгружаем
EXEC sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO

EXEC sp_configure 'xp_cmdshell', 1;  
GO  
RECONFIGURE;  
GO  

EXEC sp_configure 'show advanced options', 0
GO
RECONFIGURE
GO

-- Пришлось городить процедуру, если  использовать без процедуры, запросом, ничего не выгружается. 
-- Сам запрос закомментирован ниже 
IF OBJECT_ID('dbo.usp_StockItems_XML') IS NOT NULL DROP PROC dbo.usp_StockItems_XML
GO

CREATE PROC dbo.usp_StockItems_XML AS

SET NOCOUNT ON

SELECT 
    [StockItemName] AS [@Name],
    [SupplierID] AS [SupplierID],
    [UnitPackageID] AS [Package/UnitPackageID],
    [OuterPackageID] AS [Package/OuterPackageID],
    [QuantityPerOuter] AS [Package/QuantityPerOuter],
    [TypicalWeightPerUnit] AS [Package/TypicalWeightPerUnit],
    [LeadTimeDays] AS [LeadTimeDays],
    [IsChillerStock] AS [IsChillerStock],
    [TaxRate] AS [TaxRate],
	[UnitPrice] AS [UnitPrice]
FROM Warehouse.StockItems as i
FOR XML PATH('Item'), ROOT('StockItems'), TYPE

RETURN
GO

-- Сформированный файл прилагаю. 
EXEC xp_cmdshell 'bcp "EXEC WideWorldImporters.dbo.usp_StockItems_XML" queryout "D:Test\StockItems_XML.xml" -S GA\SQL2022 -T -w'


-- Не работает напрямую. Реализовано выше через SP 
--DECLARE @FileName VARCHAR(50)
--DECLARE @SQLCmd   VARCHAR(2000)

--SELECT  @FileName = '"D:Test\InvoiceLines.xml"'

-- SELECT  @SQLCmd = 'bcp ' +
--						'"SELECT 
--							[StockItemName] AS [@Name],
--							[SupplierID] AS [SupplierID],
--							[UnitPackageID] AS [Package/UnitPackageID],
--							[OuterPackageID] AS [Package/OuterPackageID],
--							[QuantityPerOuter] AS [Package/QuantityPerOuter],
--							[TypicalWeightPerUnit] AS [Package/TypicalWeightPerUnit],
--							[LeadTimeDays] AS [LeadTimeDays],
--							[IsChillerStock] AS [IsChillerStock],
--							[TaxRate] AS [TaxRate],
--							[UnitPrice] AS [UnitPrice]
--						FROM Warehouse.StockItems as i ' +
--						' FOR XML  PATH(''Item''), ROOT(''StockItems''), TYPE "' +
--						' queryout '  +
--						 @FileName +
--                  ' -w -T -S ' + @@SERVERNAME

-- -- Проверяем @SQLCmd
-- SELECT @SQLCmd AS 'Command to execute'

-- EXECUTE master..xp_cmdshell @SQLCmd

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT
  StockItemID
, StockItemName
, CustomFields
,   JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture
,    JSON_VALUE(CustomFields, '$.Tags[0]') AS FirstTag
FROM Warehouse.StockItems as i

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

--можно, наверное, было как-то использовать   WITHOUT_ARRAY_WRAPPER, но параметр, если я правильно понял, убирает только квадратные скобки, нам нужно убрать и кавычки
SELECT
  StockItemID
, StockItemName
--,  JSON_Query(CustomFields, '$.Tags')  AS Tags
, REPLACE ( REPLACE (REPLACE (JSON_Query(CustomFields, '$.Tags'), '[',  ''),  '"','') ,  ']','') as Tags
FROM Warehouse.StockItems as i
CROSS APPLY OPENJSON(CustomFields, '$.Tags') Tags
WHERE Tags.value = 'Vintage'
