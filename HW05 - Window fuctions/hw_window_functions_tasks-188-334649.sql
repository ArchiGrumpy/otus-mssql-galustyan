/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

SET STATISTICS TIME, IO ON

;WITH InvoiceCTE (InvoiceID, CustomerID, InvoiceDate, InvSum, InvMonth) AS
(
SELECT i.InvoiceID, i.CustomerID, i.InvoiceDate, SUM(il.UnitPrice*il.Quantity) as InvSum, Month(i.InvoiceDate) as InvMonth
FROM Sales.Invoices as i
INNER JOIN Sales.InvoiceLines as il ON il.InvoiceID = i.InvoiceID
WHERE i.InvoiceDate between '20150101' AND '20151231'
GROUP BY i.InvoiceID, i.CustomerID, i.InvoiceDate, Month(i.InvoiceDate)
),
InvoiceSumCTE (InvMonth,InvSum) AS
(
SELECT MONTH(i.invoicedate), SUM(il.UnitPrice*il.Quantity) as InvSum
FROM Sales.Invoices as i
INNER JOIN Sales.InvoiceLines as il ON il.InvoiceID = i.InvoiceID
WHERE i.InvoiceDate between '20150101' AND '20151231'
GROUP BY  MONTH(i.invoicedate)
),
InvoiceCumSumCTE (InvMonth,InvSum) AS
( 
SELECT TOP 1  InvMonth, InvSum
FROM InvoiceSumCTE
ORDER BY InvMonth
UNION ALL
SELECT r.InvMonth, c.InvSum + r.InvSum 
FROM InvoiceCumSumCTE as c
INNER JOIN InvoiceSumCTE r ON  r.InvMonth = c.InvMonth+1
)
SELECT c.* , cum.InvSum as InvCumSum
FROM InvoiceCTE as c
INNER JOIN InvoiceCumSumCTE as cum ON c.InvMonth = cum.InvMonth
ORDER BY c.InvoiceDate, c.InvoiceID -- Для читабельности данных/ InvMonth в SELECT тоже для читабельности полученных данных

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

SELECT t.*
		,SUM(t.InvSum) OVER (ORDER BY   t.InvMonth ) AS cum
FROM (
		SELECT i.InvoiceID, i.CustomerID, i.InvoiceDate, SUM(il.UnitPrice*il.Quantity) as InvSum, Month(i.InvoiceDate) as InvMonth
		FROM Sales.Invoices as i
		INNER JOIN Sales.InvoiceLines as il ON il.InvoiceID = i.InvoiceID
		WHERE i.InvoiceDate between '20150101' AND '20151231'
		GROUP BY i.InvoiceID, i.CustomerID, i.InvoiceDate
	) t
ORDER BY t.InvoiceDate, t.InvoiceID -- Для читабельности данных

SET STATISTICS TIME, IO OFF
-- При сравнении производительности видим, что запрос с оконной функцией выигрывает (чем больше показатели, тем хуже):
-- 1 запрос / 2 запрос
-- Таблица "InvoiceLines". Сканирований 41/16  Считано сегментов 13/1
-- Таблица "Invoices". Сканирований 22/9 логических операций чтения 160194/11994
--  Время работы SQL Server:
--   Время ЦП = 1000 мс/156 мс, затраченное время = 1170 мс/893.
-- Если посмортеть план, то картина аналогичная, второй запрос прилично выигрывает по стоимости по отношению к пакету.
-- План прилагаю - hw_window_fuctions_task_2_showplan

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

-- Приложен план - hw_window_fuctions_task_3_showplan_optional
;WITH MonthsCTE(m) as
(
SELECT distinct Month(i.InvoiceDate) as m
FROM Sales.Invoices as i 
WHERE i.InvoiceDate between '20160101' AND '20161231'
),
CntCTE (StockItemID,cnt, SaleMonth) AS
(SELECT  il.StockItemID, COUNT(il.Quantity) cnt, month(i.InvoiceDate) as m
FROM Sales.InvoiceLines as il
INNER JOIN Sales.Invoices as i ON i.InvoiceID = il.InvoiceID
WHERE i.InvoiceDate between '20160101' AND '20161231'
GROUP BY il.StockItemID, month(i.InvoiceDate)
)
SELECT  t.SaleMonth, t.StockItemID, StockItemName, cnt as SaleCount
FROM MonthsCTE
CROSS APPLY 
(
SELECT TOP 2 WITH TIES   il.StockItemID, cnt, SaleMonth
FROM CntCTE as il
WHERE SaleMonth = MonthsCTE.m
ORDER BY cnt DESC
) t
INNER JOIN Warehouse.StockItems as si ON si.StockItemID = t.StockItemID
ORDER BY   m, cnt DESC

-- Window function
SELECT m as SaleMonth,  StockItemID, StockItemName, cnt as SaleCount
FROM (
SELECT il.StockItemID
, si.StockItemName
, COUNT(il.Quantity)  cnt
, ROW_NUMBER() OVER ( partition by month(i.InvoiceDate) Order by COUNT(il.Quantity) DESC ) as rn
, month(i.invoiceDate) as m
FROM Sales.InvoiceLines as il
INNER JOIN Sales.Invoices as i ON i.InvoiceID = il.InvoiceID
INNER JOIN Warehouse.StockItems as si ON si.StockItemID = il.StockItemID
WHERE i.InvoiceDate between '20160101' AND '20161231'
GROUP BY il.StockItemID,  month(i.invoiceDate) , si.StockItemName
	) as t
WHERE rn <=2
ORDER BY m, cnt DESC,StockItemName -- для читабельности выборки

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

SELECT i.StockItemID, i.StockItemName, i.Brand, i.UnitPrice
, ROW_NUMBER() OVER ( partition by LEFT(StockItemName, 1)    Order by StockItemName  ) as rn_name
, COUNT (*)  OVER () as cnt_items
, COUNT (*)  OVER (partition by LEFT(StockItemName, 1)  Order by LEFT(StockItemName, 1)) as cnt_item_by_name
, LEAD(i.StockItemID) OVER (Order by StockItemName) as FollowID
, LAG(i.StockItemID) OVER (Order by StockItemName) as PrevID
, LAG(i.StockItemName,2,'No items') OVER (Order by StockItemName) as prev -- в ТЗ не указана сортировка, вязл смелость предположить, что тоже по имени
, NTILE(30) OVER (ORDER BY i.TypicalWeightPerUnit) AS GroupNumber
FROM Warehouse.StockItems as i 
ORDER BY i.StockItemName -- for the readability of the query

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

-- непонятно откуда взять фамилию. Взял полное имя
-- приложен план - hw_window_fuctions_task_5_showplan_optional
SET NOCOUNT ON
;WITH InvoiceSumCTE (SalesPersonID, SalesPersonName, CustomerID, CustomerName, InvoiceDate, InvSum, InvoiceID) AS
(
SELECT i.SalespersonPersonID, p.FullName, i.CustomerID, c.CustomerName, i.InvoiceDate,  SUM(il.UnitPrice*il.Quantity) as InvSum, i.InvoiceID
FROM Sales.Invoices as i
INNER JOIN Sales.InvoiceLines as il ON il.InvoiceID = i.InvoiceID
INNER JOIN Application.People as p ON p.PersonID = i.SalespersonPersonID
INNER JOIN Sales.Customers as c ON i.CustomerID = c.CustomerID
GROUP BY  i.SalespersonPersonID, i.InvoiceDate, p.FullName, i.CustomerID, c.CustomerName, i.InvoiceID
),
SalesPersonCTE (SalesPersonID, SalesPersonName) AS
(
SELECT distinct  i.SalespersonPersonID, p.FullName
FROM Sales.Invoices as i
INNER JOIN Application.People as p ON p.PersonID = i.SalespersonPersonID
)
SELECT * FROM SalesPersonCTE as i
CROSS APPLY 
(
SELECT TOP 1    il.CustomerID, il.CustomerName, MAX(il.InvoiceDate) as InvoiceDate,   il.InvSum
FROM InvoiceSumCTE as il
WHERE il.SalesPersonID = i.SalesPersonID
GROUP BY  il.CustomerID, il.CustomerName,   il.InvSum, il.InvoiceID
ORDER BY InvoiceDate DESC, il.InvoiceID DESC
) t

--Window function 
SELECT t.SalespersonPersonID as SalesPersonID 
, t.FullName as SalesPersonName
, t.CustomerID, t.CustomerName, t.InvoiceDate,  t. InvSum
FROM (
		SELECT i.SalespersonPersonID, p.FullName, i.CustomerID, c.CustomerName, i.InvoiceDate,  SUM(il.UnitPrice*il.Quantity) as InvSum, i.InvoiceID
		, ROW_NUMBER() OVER (partition by i.SalespersonPersonID ORDER BY  i.InvoiceDate DESC, i.InvoiceID DESC ) as rn
		FROM Sales.Invoices as i
		INNER JOIN Sales.InvoiceLines as il ON il.InvoiceID = i.InvoiceID
		INNER JOIN Application.People as p ON p.PersonID = i.SalespersonPersonID
		INNER JOIN Sales.Customers as c ON i.CustomerID = c.CustomerID
		GROUP BY  i.SalespersonPersonID, i.InvoiceDate, p.FullName, i.CustomerID, c.CustomerName, i.InvoiceID
	) as t
WHERE t.rn = 1  
SET NOCOUNT OFF

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

-- вопрос звучит неоднозначно: 1) два дорогих товара, которые покупал клиент, могли покупаться в разные даты. Вывел все совпадения
--							   2) у нескольких товаров может быть одна и та же цена, если сортировать по цене 2 самые высокие цены, то товаров может быть больше - /*with ties*/
--							   3) дополнительно привязал AND t.UnitPrice = tt.UnitPrice,
--								так как цена у одного и того же изделия могла варьироваться и полученные данные будут некорректными,
--								например  CustomerID = 160, StockItemID = 15, UnitPrice 240 и 36 в разных продажах
-- план прилагаю
;WITH CustomerCTE (CustomerID, CustomerName) AS
(
SELECT c.CustomerID, c.CustomerName
FROM  Sales.Customers as c 
),
InvoiceCTE (CustomerID, StockItemID, UnitPrice,  InvoiceDate, InvoiceID) AS
(
SELECT i.CustomerID, il.StockItemID,  il.UnitPrice, i.InvoiceDate, i.InvoiceID
FROM Sales.Invoices as i
INNER JOIN Sales.InvoiceLines as il ON il.InvoiceID = i.InvoiceID
INNER JOIN Warehouse.StockItems as si  ON si.StockItemID = il.StockItemID
)
SELECT c.CustomerID, c.CustomerName, t.StockItemID, t.UnitPrice, tt.InvoiceDate--, tt.InvoiceID
FROM CustomerCTE as c
CROSS APPLY 
(
SELECT TOP 2 /*with ties*/  il.StockItemID, il.UnitPrice, il.CustomerID
FROM InvoiceCTE as il
WHERE il.CustomerID = c.CustomerID
GROUP BY il.StockItemID, il.UnitPrice, il.CustomerID
ORDER BY il.UnitPrice DESC
) t
INNER JOIN InvoiceCTE as tt ON t.StockItemID = tt.StockItemID AND  t.CustomerID = tt.CustomerID AND t.UnitPrice = tt.UnitPrice
ORDER BY c.CustomerID, tt.InvoiceDate, t.StockItemID -- для читабельности выборки

-- Window function
-- у нескольких товаров может быть одна и та же цена, если сортировать по цене 2 самые высокие цены, то товаров может быть больше. 
-- Взял согласно заданию 2 товара, 
SELECT t.CustomerID, t.CustomerName, t.StockItemID,  t.UnitPrice, t.InvoiceDate--, i.InvoiceID
FROM (
SELECT i.CustomerID, c.CustomerName, il.StockItemID,  il.UnitPrice, i.InvoiceDate--, i.InvoiceID
,RANK() OVER (PARTITION BY i.CustomerID  ORDER BY il.UnitPrice DESC) AS rnk
,DENSE_RANK() OVER (PARTITION BY i.CustomerID ORDER BY il.UnitPrice DESC, il.StockItemID) AS dense_rnk
FROM Sales.Invoices as i
INNER JOIN Sales.InvoiceLines as il ON il.InvoiceID = i.InvoiceID
INNER JOIN Warehouse.StockItems as si  ON si.StockItemID = il.StockItemID
INNER JOIN  Sales.Customers as c  ON c.CustomerID = i.CustomerID
	) as t
	WHERE t.dense_rnk <=2
ORDER BY t.CustomerID, t.InvoiceDate, t.StockItemID -- для читабельности выборки


-- Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 
-- Реализовано в задачах. Планы приложены.