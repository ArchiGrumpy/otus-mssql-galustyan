/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT i.StockItemID,  i.StockItemName 
FROM Warehouse.StockItems  as i
WHERE i.StockItemName LIKE '%urgent%'  OR i.StockItemName LIKE 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT s.SupplierID, SupplierName
FROM Purchasing.Suppliers as s
LEFT JOIN Purchasing.PurchaseOrders as o ON s.SupplierID = o.SupplierID
WHERE o.SupplierID IS NULL

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT DISTINCT 
o.OrderID
,FORMAT (o.OrderDate, 'd', 'de-de') as OrderDate 
,DATENAME(month, o.OrderDate)  as OrderMonth
,DATEPART(QUARTER, o.OrderDate) as OrderQuarter 
,CASE
	WHEN month(o.OrderDate) <=4 THEN 1
	WHEN month(o.OrderDate) between 5 AND 8 THEN 2
	ELSE 3
 END  as OrderTrimester
,c.CustomerName as Customer
FROM Sales.Orders as o 
INNER JOIN Sales.Customers as c ON o.CustomerID = c.CustomerID
INNER JOIN Sales.OrderLines as l ON o.OrderID = l.OrderID
WHERE l.UnitPrice > 100
	OR  (Quantity > 20  AND o.PickingCompletedWhen is not null
		)
ORDER BY  OrderQuarter , OrderTrimester, OrderDate
GO 

SELECT DISTINCT 
o.OrderID
,FORMAT (o.OrderDate, 'd', 'de-de') as OrderDate 
,DATENAME(month, o.OrderDate)  as OrderMonth
,DATEPART(QUARTER, o.OrderDate) as OrderQuarter 
,CASE
	WHEN month(o.OrderDate) <=4 THEN 1
	WHEN month(o.OrderDate) between 5 AND 8 THEN 2
	ELSE 3
 END  as OrderTrimester
,c.CustomerName as Customer
FROM Sales.Orders as o 
INNER JOIN Sales.Customers as c ON o.CustomerID = c.CustomerID
INNER JOIN Sales.OrderLines as l ON o.OrderID = l.OrderID
WHERE l.UnitPrice > 100
	OR  (Quantity > 20  AND o.PickingCompletedWhen is not null
		)
ORDER BY  OrderQuarter , OrderTrimester, OrderDate
OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY; 
GO

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT 
  m.DeliveryMethodName
, o.ExpectedDeliveryDate
, s.SupplierName
, p.FullName as ContactPerson  --,p.PreferredName OR , p.SearchName
FROM Purchasing.Suppliers as s
INNER JOIN Purchasing.PurchaseOrders  as o ON s.supplierID =  o.supplierID 
INNER JOIN Application.DeliveryMethods as m ON m.DeliveryMethodID = o.DeliveryMethodID
INNER JOiN Application.People as p ON p.PersonID = o.ContactPersonID
WHERE (ExpectedDeliveryDate between '20130101' AND '20130131')
	AND (o.DeliveryMethodID = 8 OR  o.DeliveryMethodID = 10) 
	 --AND (m.DeliveryMethodName  = 'Air Freight' OR  m.DeliveryMethodName  = 'Refrigerated Air Freight') 
	 AND o.IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT top 10 
  i.* -- в задании не указано какие поля нужны для отображения
, c.CustomerName
, p.FullName as SalespersonPerson
FROM Sales.Invoices as i
INNER JOIN Sales.Customers as c ON i.CustomerID  = c.CustomerID
INNER JOIN Application.People as p ON  p.PersonID = i.SalespersonPersonID
ORDER BY i.InvoiceDate desc

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT DISTINCT
  c.CustomerID
, c.CustomerName
, c.PhoneNumber
FROM Sales.Customers as c 
INNER JOIN Sales.Invoices as i ON i.CustomerID = c.CustomerID
INNER JOIN Sales.Invoicelines as l ON l.InvoiceID = i.InvoiceID
INNER JOIN Warehouse.StockItems as si ON si.StockItemID = l.StockItemID
WHERE si.StockItemName = 'Chocolate frogs 250g'

 