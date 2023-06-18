SET STATISTICS io, time on--, profile off;
--dbcc freeproccache;


-- Исходный запрос для оптимизации. 
-- Добавил сюда, чтоб можно было проверить стоимость запроса по отноешнию к пакету
Select ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM Sales.Orders AS ord
JOIN  Sales.OrderLines AS det
ON det.OrderID = ord.OrderID
JOIN Sales.Invoices AS Inv
ON Inv.OrderID = ord.OrderID
JOIN Sales.CustomerTransactions AS Trans
ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions AS ItemTrans
ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
AND (Select SupplierId
FROM Warehouse.StockItems AS It
Where It.StockItemID = det.StockItemID) = 12
AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
FROM Sales.OrderLines AS Total
Join Sales.Orders AS ordTotal
On ordTotal.OrderID = Total.OrderID
WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

-- Оptimization WITH HINTS
-- Для удобства создаем CTE и выносим подзапрос в JOIN (оптимизация только визуальная).
-- Указываем, что все операции соединения во всем запросе выполняются с помощью HASH JOIN - выигрыш в производительности.
-- Чтоб наш хинт сработал мы добавляем табличный хинт WITH (INDEX = FK_Sales_Invoices_CustomerID ) на таблицу Sales.Invoices
--	так как у нас быть условие с этим полем и очень нам поможет.
-- Стоиомость запроса к пакету: 61% (исходный) vs 39% (оптимизированный).
-- План в папке "HW31 - Hints" (файл Plan_Query_Optimization.sqlplan).
-- Скорее всего можно еще как-то оптимизировать, но не дошли руки (катастрофически не хватает времени) :)
;WITH OrdersCTE (CustomerID, OrderID, OrderDate) AS 
(
	SELECT ord.CustomerID, ord.OrderID, ord.OrderDate
	FROM Sales.Orders AS ord
)
,
OrderLinesCTE (OrderID,StockItemID, UnitPrice, Quantity) AS 
(
	SELECT det.OrderID, det.StockItemID, (det.UnitPrice), (det.Quantity)
	FROM Sales.OrderLines AS det
	--GROUP BY det.OrderID, det.StockItemID
)
SELECT ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)
FROM OrdersCTE AS ord
INNER  JOIN  OrderLinesCTE AS det						ON det.OrderID = ord.OrderID
INNER JOIN Warehouse.StockItems AS It					ON It.StockItemID = det.StockItemID
INNER  JOIN  Sales.Invoices AS Inv  WITH (INDEX = FK_Sales_Invoices_CustomerID ) ON Inv.OrderID = ord.OrderID  
INNER JOIN Sales.CustomerTransactions AS Trans			ON Trans.InvoiceID = Inv.InvoiceID
INNER JOIN Warehouse.StockItemTransactions AS ItemTrans	ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
	AND It.SupplierID = 12
	AND (	SELECT SUM(Total.UnitPrice*Total.Quantity)
			FROM OrderLinesCTE AS Total
			INNER JOIN OrdersCTE AS ordTotal ON ordTotal.OrderID = Total.OrderID
			WHERE ordTotal.CustomerID = Inv.CustomerID ) > 250000
	AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID
OPTION (HASH JOIN);