SET STATISTICS io, time on--, profile off;
--dbcc freeproccache;


-- �������� ������ ��� �����������. 
-- ������� ����, ���� ����� ���� ��������� ��������� ������� �� ��������� � ������
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

-- �ptimization WITH HINTS
-- ��� �������� ������� CTE � ������� ��������� � JOIN (����������� ������ ����������).
-- ���������, ��� ��� �������� ���������� �� ���� ������� ����������� � ������� HASH JOIN - ������� � ������������������.
-- ���� ��� ���� �������� �� ��������� ��������� ���� WITH (INDEX = FK_Sales_Invoices_CustomerID ) �� ������� Sales.Invoices
--	��� ��� � ��� ���� ������� � ���� ����� � ����� ��� �������.
-- ���������� ������� � ������: 61% (��������) vs 39% (����������������).
-- ���� � ����� "HW31 - Hints" (���� Plan_Query_Optimization.sqlplan).
-- ������ ����� ����� ��� ���-�� ��������������, �� �� ����� ���� (��������������� �� ������� �������) :)
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