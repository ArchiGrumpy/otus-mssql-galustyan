/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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

USE WideWorldImporters

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

SELECT 
	   NEXT VALUE FOR Sequences.SupplierID as [SupplierID]
      ,[SupplierName] +  CAST( NEXT VALUE FOR Sequences.SupplierID as nvarchar(10))
      ,[SupplierCategoryID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[SupplierReference]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryPostalCode]
      ,[PostalAddressLine1]
      ,[PostalPostalCode]
      ,[LastEditedBy]
	  --,[ValidFrom] -- не вставляем эти поля, формируются автоматически, иначе будет ошибка из-за 	PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
	  --,[ValidTo]
FROM [WideWorldImporters].[Purchasing].[Suppliers] as s
WHERE s.[SupplierID] between 3 AND 7

INSERT INTO [WideWorldImporters].[Purchasing].[Suppliers]  (
	   [SupplierID]
      ,[SupplierName] 
      ,[SupplierCategoryID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[SupplierReference]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryPostalCode]
      ,[PostalAddressLine1]
      ,[PostalPostalCode]
      ,[LastEditedBy]
      --,[ValidFrom] -- 
      --,[ValidTo]
	  )
	  OUTPUT inserted.*
SELECT 
	   NEXT VALUE FOR Sequences.SupplierID as [SupplierID]
      ,[SupplierName] +  CAST( NEXT VALUE FOR Sequences.SupplierID as nvarchar(10))
      ,[SupplierCategoryID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[SupplierReference]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryPostalCode]
      ,[PostalAddressLine1]
      ,[PostalPostalCode]
      ,[LastEditedBy]
	  --,[ValidFrom]
	  --,[ValidTo]
FROM [WideWorldImporters].[Purchasing].[Suppliers] as s
WHERE s.[SupplierID] between 3 AND 7

/*
2. Удалите одну запись из Customers или Suppliers, которая была вами добавлена
*/

-- просмотр
;WITH del AS 
(
select	top 1	s.SupplierID
FROM [WideWorldImporters].[Purchasing].[Suppliers] as s
WHERE s.ValidFrom >= '20230308'
) 
SELECT * 
FROM del

-- удаление 
;WITH del AS 
(
select	top 1	*
FROM [WideWorldImporters].[Purchasing].[Suppliers] as s
WHERE s.ValidFrom >= '20230308'
) 
DELETE d
FROM del as d

/*
3. Изменить одну запись, из добавленных через UPDATE
*/

-- просмотр
;WITH upd AS 
(
select	top 1	*
FROM [WideWorldImporters].[Purchasing].[Suppliers] as s
WHERE s.ValidFrom >= '20230308'
) 
SELECT * 
FROM upd

-- обновление 
;WITH upd AS 
(
select	top 1	*
FROM [WideWorldImporters].[Purchasing].[Suppliers] as s
WHERE s.ValidFrom >= '20230308'
) 
UPDATE u
SET u.DeliveryAddressLine2 = 'Leve l3'
OUTPUT deleted.*,  inserted.* -- $action не работает
FROM upd as u

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

-- генерируем входные данные 
SELECT top 1

	[CustomerID],
	[CustomerName],
	[BillToCustomerID],
	[CustomerCategoryID],
	[PrimaryContactPersonID],
	[DeliveryMethodID],
	[DeliveryCityID],
	[PostalCityID],
	[AccountOpenedDate],
	[StandardDiscountPercentage],
	[IsStatementSent],
	[IsOnCreditHold],
	[PaymentDays],
	[PhoneNumber],
	[FaxNumber],
	[WebsiteURL],
	[DeliveryAddressLine1],
	[DeliveryPostalCode],
	[PostalAddressLine1],
	[PostalPostalCode],
	[LastEditedBy]
INTO [Sales].[Customers_tmp] 
FROM [Sales].[Customers]

INSERT INTO 
[Sales].[Customers_tmp] ( 	[CustomerID],
							[CustomerName],
							[BillToCustomerID],
							[CustomerCategoryID],
							[PrimaryContactPersonID],
							[DeliveryMethodID],
							[DeliveryCityID],
							[PostalCityID],
							[AccountOpenedDate],
							[StandardDiscountPercentage],
							[IsStatementSent],
							[IsOnCreditHold],
							[PaymentDays],
							[PhoneNumber],
							[FaxNumber],
							[WebsiteURL],
							[DeliveryAddressLine1],
							[DeliveryPostalCode],
							[PostalAddressLine1],
							[PostalPostalCode],
							[LastEditedBy])
SELECT	NEXT VALUE FOR Sequences.[CustomerID] as [CustomerID],
		([CustomerName] +  CAST( NEXT VALUE FOR Sequences.[CustomerID] as nvarchar(10))) as [CustomerName],
		[BillToCustomerID],
		[CustomerCategoryID],
		[PrimaryContactPersonID],
		[DeliveryMethodID],
		[DeliveryCityID],
		[PostalCityID],
		[AccountOpenedDate],
		[StandardDiscountPercentage],
		[IsStatementSent],
		[IsOnCreditHold],
		[PaymentDays],
		[PhoneNumber],
		[FaxNumber],
		[WebsiteURL],
		[DeliveryAddressLine1],
		[DeliveryPostalCode],
		[PostalAddressLine1],
		[PostalPostalCode],
		[LastEditedBy]
FROM [Sales].[Customers_tmp] as t

-- просмотр входных данных 
SELECT * FROM [Sales].[Customers_tmp] as t
-- для предварительной проверки целевой таблицы
SELECT max(c.customerid) FROM [Sales].[Customers] as c

-- проверка
SELECT * 
FROM [Sales].[Customers_tmp] as t
LEFT JOIN  [Sales].[Customers] as c ON c.CustomerID = t.CustomerID

-- MERGE
MERGE Sales.[Customers] AS target 
	USING (SELECT * FROM [Sales].[Customers_tmp] as t
		) 
		AS source (			[CustomerID],
							[CustomerName],
							[BillToCustomerID],
							[CustomerCategoryID],
							[PrimaryContactPersonID],
							[DeliveryMethodID],
							[DeliveryCityID],
							[PostalCityID],
							[AccountOpenedDate],
							[StandardDiscountPercentage],
							[IsStatementSent],
							[IsOnCreditHold],
							[PaymentDays],
							[PhoneNumber],
							[FaxNumber],
							[WebsiteURL],
							[DeliveryAddressLine1],
							[DeliveryPostalCode],
							[PostalAddressLine1],
							[PostalPostalCode],
							[LastEditedBy]) 
		ON
	 (target.CustomerID = source.CustomerID) 
	WHEN MATCHED 
		THEN UPDATE SET [CustomerName] = source.[CustomerName] + ' UPDATE'
	WHEN NOT MATCHED 
		THEN INSERT ([CustomerID], [CustomerName], [BillToCustomerID], [CustomerCategoryID], [PrimaryContactPersonID], [DeliveryMethodID], [DeliveryCityID], [PostalCityID], [AccountOpenedDate], [StandardDiscountPercentage],
					 [IsStatementSent], [IsOnCreditHold], [PaymentDays], [PhoneNumber], [FaxNumber], [WebsiteURL], [DeliveryAddressLine1], [DeliveryPostalCode], [PostalAddressLine1], [PostalPostalCode], [LastEditedBy]) 
			VALUES (		source.[CustomerID],
							source.[CustomerName],
							source.[BillToCustomerID],
							source.[CustomerCategoryID],
							source.[PrimaryContactPersonID],
							source.[DeliveryMethodID],
							source.[DeliveryCityID],
							source.[PostalCityID],
							source.[AccountOpenedDate],
							source.[StandardDiscountPercentage],
							source.[IsStatementSent],
							source.[IsOnCreditHold],
							source.[PaymentDays],
							source.[PhoneNumber],
							source.[FaxNumber],
							source.[WebsiteURL],
							source.[DeliveryAddressLine1],
							source.[DeliveryPostalCode],
							source.[PostalAddressLine1],
							source.[PostalPostalCode],
							source.[LastEditedBy]) 
	OUTPUT deleted.*, $action, inserted.*;


/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

EXEC sp_configure 'xp_cmdshell', 1;  
GO  

RECONFIGURE;  
GO  
SELECT @@SERVERNAME

EXEC master..xp_cmdshell 'bcp "[WideWorldImporters].Sales.InvoiceLines" out  "D:\Test\InvoiceLines.txt" -T -w -t "@ggt#" -S GA\SQL2022'

-- создаем только табдицу для загрузки
SELECT *
INTO [WideWorldImporters].[Sales].[InvoiceLines_BulkDemo]   
FROM [WideWorldImporters].[Sales].[InvoiceLines]  
WHERE  1= 2

BULK INSERT [WideWorldImporters].[Sales].[InvoiceLines_BulkDemo]   
				FROM  "D:\Test\InvoiceLines.txt"
				WITH 
					(
					BATCHSIZE = 1000, 
					DATAFILETYPE = 'widechar',
					FIELDTERMINATOR = '@ggt#',
					ROWTERMINATOR ='\n',
					KEEPNULLS,
					TABLOCK        
					);

-- проверка данных 
SELECT * FROM [WideWorldImporters].[Sales].[InvoiceLines_BulkDemo]   