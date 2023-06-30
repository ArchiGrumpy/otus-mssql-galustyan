-- Заполняем нашу таблицы данными 

-- Заполняем [Production].[dbo].[Counteragents] 
SET IDENTITY_INSERT [Production].[dbo].[Counteragents]  ON;  
INSERT INTO [Production].[dbo].[Counteragents] 
(      [CounteragentId]
	  ,[CounteragentName]
      ,[Address]
      ,[Phone]
      ,[CounteragentType]
      ,[WebsiteURL]
 )
SELECT   c.CustomerID
		,c.[CustomerName]
        ,c.[DeliveryAddressLine2]
		,c.[PhoneNumber]
		,2 as [CounteragentType] -- 2- customer. 1 - supplier
		,c.[WebsiteURL]
FROM [WideWorldImporters].[Sales].[Customers] as c
WHERE c.CustomerID > 17
SET IDENTITY_INSERT [Production].[dbo].[Counteragents]  OFF;  

--Проверка данных
SELECT * FROM [dbo].[Counteragents]

-- Заполняем [Production].[dbo].[Docs]
SET IDENTITY_INSERT [Production].[dbo].[Docs]  ON; 
INSERT INTO [Production].[dbo].[Docs]
	(  [DocId]
	  ,[Docname]
      ,[DocTypeID]
      ,[Comment]
      ,[WarehouseId]
      ,[LocationID]
      ,[CreateDate]
      ,[CounteragentId])
 SELECT 
		[InvoiceID],
	  CASE WHEN FLOOR(RAND([InvoiceID])*(4-1+1))+1 = 1 THEN 'Приход №' + CAST([InvoiceID] as nvarchar)
			WHEN FLOOR(RAND([InvoiceID])*(4-1+1))+1 = 2 THEN 'Расход №' + CAST([InvoiceID] as nvarchar)
			WHEN FLOOR(RAND([InvoiceID])*(4-1+1))+1 = 3 THEN 'Временный приход №' + CAST([InvoiceID] as nvarchar)
			WHEN FLOOR(RAND([InvoiceID])*(4-1+1))+1 = 4 THEN 'Временный расход №' + CAST([InvoiceID] as nvarchar)
	  END as [Docname]
      ,FLOOR(RAND([InvoiceID])*(4-1+1))+1 as [DocTypeID]
      ,[Comments]
	  ,FLOOR(RAND([InvoiceID])*(3-1+1))+1 as [WarehouseId]
      ,FLOOR(RAND([InvoiceID])*(6-1+1))+1  as [LocationID]
      ,[InvoiceDate]
	  ,[CustomerID]
  FROM [WideWorldImporters].[Sales].[Invoices]
SET IDENTITY_INSERT [Production].[dbo].[Docs]  OFF; 

--Проверка данных
SELECT [DocId],
       [Docname]
      ,[DocTypeID]
      ,[Comment]
      ,[WarehouseId]
      ,[LocationID]
      ,[CreateDate]
      ,[CounteragentId]
  FROM [Production].[dbo].[Docs]

-- Заполняем [Production].[dbo].[Products]
SET IDENTITY_INSERT [Production].[dbo].[Products]  ON; 
INSERT INTO [Production].[dbo].[Products] (
	   [ProductId]
      ,[ProductName]
      ,[ProductExtName]
      ,[Photo]
      ,[BrandID] )
SELECT [StockItemID]
      ,[StockItemName]
      ,[StockItemName]
	  ,[Photo]
      ,[BrandId]
FROM [WideWorldImporters].[Warehouse].[StockItems] as i
LEFT JOIN [Production].[dbo].[Brands] as b ON b.Brand  = i.Brand COLLATE Cyrillic_General_CI_AS
SET IDENTITY_INSERT [Production].[dbo].[Products]  OFF; 