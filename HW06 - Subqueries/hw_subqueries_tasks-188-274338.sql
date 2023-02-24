/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

TODO: 
SELECT p.PersonID, p.FullName
FROM Application.People as p
WHERE p.IsSalesPerson = 1
	AND p.PersonID NOT IN (	SELECT i.SalespersonPersonID
									FROM Sales.Invoices as i
									WHERE i.InvoiceDate = '20150704'
								)
-- CTE 		
;WITH InvoicesCTE (SalespersonPersonID) AS 
(
	SELECT distinct i.SalespersonPersonID
	FROM Sales.Invoices as i
	WHERE i.InvoiceDate = '20150704'
)
SELECT P.PersonID, P.FullName
FROM Application.People as p
LEFT JOIN InvoicesCTE AS i
		ON p.PersonID = i.SalespersonPersonID
WHERE p.IsSalesPerson = 1 
	AND i.SalespersonPersonID IS NULL;

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

-- I вариант
TODO: 
SELECT i.StockItemID, i.StockItemName, i.UnitPrice 
FROM Warehouse.StockItems as i
WHERE i.UnitPrice <= ALL ( 	SELECT UnitPrice 
							FROM Warehouse.StockItems);
-- CTE 		
;WITH StockItemsCTE (UnitPrice) AS 
(
	SELECT UnitPrice 
	FROM Warehouse.StockItems
)
SELECT i.StockItemID, i.StockItemName, i.UnitPrice 
FROM Warehouse.StockItems as i
WHERE i.UnitPrice <= ALL ( 	SELECT UnitPrice 
							FROM StockItemsCTE);
-- II вариант
SELECT i.StockItemID, i.StockItemName, i.UnitPrice 
FROM Warehouse.StockItems as i
WHERE i.UnitPrice = (SELECT min(UnitPrice) FROM Warehouse.StockItems);
-- CTE 		
;WITH StockItemsCTE (UnitPrice) AS 
(
	SELECT min(UnitPrice)
	FROM Warehouse.StockItems
)
SELECT i.StockItemID, i.StockItemName, i.UnitPrice 
FROM Warehouse.StockItems as i
WHERE i.UnitPrice = (SELECT (UnitPrice) FROM StockItemsCTE);

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

TODO: 
-- В ТЗ нет информации по [TransactionTypeID], поэтому не стал вычленять в WHERE. Также не указано какая информация по клиентам необходима для отображения, поэтому * 
-- I вариант
;WITH CustomerTransactionsCTE ([CustomerID],  [TransactionAmount]) AS 
(
	SELECT TOP 5 with ties  [CustomerID], max([TransactionAmount]) as [TransactionAmount]
	FROM [WideWorldImporters].[Sales].[CustomerTransactions] as ct
	GROUP BY [CustomerID]
	ORDER BY [TransactionAmount] DESC
)
SELECT c.* , cte.[TransactionAmount]
FROM Sales.Customers as c
INNER JOIN  CustomerTransactionsCTE as cte ON c.CustomerID = cte.CustomerID

-- II вариант
;WITH CustomerTransactionsCTE ([CustomerID],  [TransactionAmount]) AS 
(
	SELECT TOP 5 with ties  [CustomerID], max([TransactionAmount]) as [TransactionAmount]
	FROM [WideWorldImporters].[Sales].[CustomerTransactions] as ct
	GROUP BY [CustomerID]
	ORDER BY [TransactionAmount] DESC
)
SELECT c.* 
FROM Sales.Customers as c
WHERE c.CustomerID IN (SELECT  [CustomerID] FROM  CustomerTransactionsCTE)

-- III вариант
SELECT c.* , t.TransactionAmount
FROM Sales.Customers as c
INNER JOIN ( SELECT TOP 5 with ties  [CustomerID], max([TransactionAmount]) as [TransactionAmount]
			 FROM [WideWorldImporters].[Sales].[CustomerTransactions] as ct
			 GROUP BY [CustomerID]
			 ORDER BY [TransactionAmount] DESC) as t ON t.CustomerID = c.CustomerID


/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

TODO:
SELECT distinct tc.CityID, tc.CityName, p.FullName
FROM  Sales.Invoices as i
INNER JOIN Sales.Invoicelines as il ON i.InvoiceID  = il.InvoiceID
INNER JOIN (SELECT  top 3 with ties  il.StockItemID, max(il.UnitPrice) as UnitPriceMax 
			FROM   Sales.Invoicelines as il
			GROUP BY il.StockItemID
			ORDER BY UnitPriceMax  DESC) as  t  ON t.StockItemID = il.StockItemID
INNER JOIN Sales.Customers as c ON c.CustomerID = i.CustomerID
INNER JOIN Application.Cities as tc ON tc.CityID = c.DeliveryCityID
INNER JOIN Application.People as p ON p.PersonID = i.PackedByPersonID

--CTE
;WITH InvoicelinesCTE (StockItemID,  UnitPriceMax) AS 
(
SELECT  top 3 with ties  il.StockItemID, max(il.UnitPrice) as UnitPriceMax 
FROM   Sales.Invoicelines as il
GROUP BY il.StockItemID
ORDER BY UnitPriceMax  DESC
)
SELECT distinct tc.CityID, tc.CityName, p.FullName
FROM  Sales.Invoices as i
INNER JOIN Sales.Invoicelines as il ON i.InvoiceID  = il.InvoiceID
INNER JOIN InvoicelinesCTE as  cte  ON cte.StockItemID = il.StockItemID
INNER JOIN Sales.Customers as c ON c.CustomerID = i.CustomerID
INNER JOIN Application.Cities as tc ON tc.CityID = c.DeliveryCityID
INNER JOIN Application.People as p ON p.PersonID = i.PackedByPersonID



-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: 
-- Запрос возвращает ID, дату, полное имя продавца, сумму собранного заказа по данной продаже, где дата сборки проставлена (не NULL), саму сумму продажи
--  по продажам, где сумма  > 27000
-- Рассуждения: 1. Перенёс подзапрос для поиска полного имени продавца для из SELECT в INNER JOIN для улучшения читабельности запроса
--				2. Сумму собранного заказа по данной продаже из SELECT перенёс в CTE для улучшения читабельности запроса
--				3. В PickedItemsCTE подзапрос в WHERE заменил на INNER JOIN для улучшения читабельности запроса и исключения ошибки "Вложенный запрос вернул больше одного значения"
--				3.1. В пункте 3 произойдет незачительное ухудшение по стоимости из-за того, что из CTE исчезнет AND Orders.OrderId = Invoices.OrderId . Вместо 50/50 будет 49/51. 
--				4. Сумму продажи вынес в CTE для улучшения читабельности запроса
--				5. Для улучшения стоимости запроса первым  задаём cte суммы продаж - TotalSummCTE, сильно ограничивая выборку, далее используем в нижестоящем CTE - PickedItemsCTE,
--				в результате выигрыш 71/29, судя по плану. План прикладываю.

;WITH 
--PickingCompletedWhenCTE (OrderId) AS
--(
--SELECT ord.OrderId
--FROM Sales.Orders  as ord
--WHERE Ord.PickingCompletedWhen IS NOT NULL
--),

TotalSummCTE (InvoiceId,  TotalSumm, OrderID) AS 
(
(SELECT Sales.InvoiceLines.InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm, i.OrderID
	FROM Sales.InvoiceLines
	INNER JOIN Sales.Invoices  as i ON i.InvoiceID = Sales.InvoiceLines.InvoiceID
	GROUP BY Sales.InvoiceLines.InvoiceId, i.OrderID
	HAVING SUM(Quantity*UnitPrice) > 27000) 
),
PickedItemsCTE (OrderId,  TotalSummForPickedItems) AS 
(
SELECT OrderLines.OrderId, SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice) as TotalSummForPickedItems
FROM Sales.Orders  as ord
--FROM PickingCompletedWhenCTE  as ord
INNER JOIN Sales.OrderLines  ON ord.OrderID = OrderLines.OrderID
INNER JOIN TotalSummCTE as t ON t.OrderID = ord.OrderID
WHERE Ord.PickingCompletedWhen IS NOT NULL
GROUP BY OrderLines.OrderId
)
SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	FullName as SalesPersonName,
	TotalSummCTE.TotalSumm AS TotalSummByInvoice, 
	piCTE.TotalSummForPickedItems
FROM Sales.Invoices 
INNER JOIN Application.People as p ON p.PersonID = Invoices.SalespersonPersonID
INNER JOIN TotalSummCTE ON  Invoices.InvoiceID = TotalSummCTE.InvoiceID
INNER JOIN PickedItemsCTE as piCTE ON piCTE.OrderId = Invoices.OrderId
ORDER BY TotalSumm DESC