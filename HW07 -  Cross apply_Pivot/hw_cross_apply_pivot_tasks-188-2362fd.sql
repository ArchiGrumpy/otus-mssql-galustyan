/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

;WITH cte as 
(
SELECT	--format (i.InvoiceDate, '01.MM.yyyy') as InvoiceMonth -- FORMAT использовал позднее, чтоб правильно отработала сортировка, иначе будет 01.01.2013, 01.01.2014 и так далее
		DATEADD(month, DATEDIFF(month, 0, i.InvoiceDate), 0)  as InvoiceMonth
		, SUBSTRING(c.CustomerName, CHARINDEX('(', c.CustomerName) +1 , LEN(c.CustomerName) -  CHARINDEX('(', c.CustomerName) -1  ) as CustomerName
		, COUNT (i.InvoiceID) as SalesCount
	 FROM Sales.Invoices AS i
	 INNER JOIN Sales.Customers as c ON c.CustomerID = i.CustomerID
	 WHERE C.CustomerID between 2 AND 6 
	 GROUP BY DATEADD(month, DATEDIFF(month, 0, i.InvoiceDate), 0)  , c.CustomerName
)
SELECT FORMAT(InvoiceMonth, '01.MM.yyyy') as InvoiceMonth , [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT], [Jessie, ND] FROM 
	(
	SELECT * FROM cte 

	) AS s
PIVOT (MAX(s.SalesCount) 
FOR CustomerName  IN ([Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT], [Jessie, ND]))
as PVT
ORDER BY PVT.InvoiceMonth -- сортировка для наглядности

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

;WITH cte as 
(
SELECT	c.CustomerName
		, c.DeliveryAddressLine1
		, c.DeliveryAddressLine2
		, c.PostalAddressLine1
		, c.PostalAddressLine2
FROM Sales.Customers as c
WHERE c.CustomerName like '%Tailspin Toys%' 
)
SELECT   CustomerName, AddressLine
FROM (
		SELECT	
				CustomerName
				, c.DeliveryAddressLine1
				, c.DeliveryAddressLine2
				, c.PostalAddressLine1
				, c.PostalAddressLine2 
		FROM cte as c
	) AS cc
UNPIVOT ( AddressLine FOR  Addr   IN (	  [DeliveryAddressLine1]
										, [DeliveryAddressLine2]
										, [PostalAddressLine1]
										, [PostalAddressLine2])) AS unpt
ORDER BY CustomerName, AddressLine;  -- сортировка для наглядности


/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

;WITH cte as 
(
SELECT	c.CountryID
		, c.CountryName
		, c.IsoAlpha3Code
		, CAST(c.IsoNumericCode as nvarchar (3)) as IsoNumericCode -- обязательно приводим к одну и тому же типу, иначе не работает в UNPIVOT  даже, если указать просто nvarchar
FROM Application.Countries as c
)
SELECT   CountryID , CountryName, Code
FROM (
		SELECT	
				 c.CountryID
				 , CountryName
				 , c.IsoAlpha3Code
				 , IsoNumericCode

		FROM cte as c
	) AS cc
UNPIVOT ( Code FOR  с   IN (IsoAlpha3Code,   IsoNumericCode
									)) AS unpt
ORDER BY CountryName, Code desc; -- сортировка для наглядности


/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT  c.CustomerID,  c.CustomerName, inv.StockItemID , inv.UnitPrice, inv.invoicedate

FROM Sales.Customers c
-- DISTINCT используем  для исключения дублей, так как 1 и тот же товар мог покупаться клиентом дважды.
CROSS APPLY (SELECT  distinct  TOP 2 /* with ties */ il.StockItemID, il.UnitPrice, i.CustomerID -- у разных товаров может быть одинаковая цена. При таком раскладе нужно использовать  with ties
									, MAX (i.invoicedate) OVER (partition by CustomerID ORDER BY il.UnitPrice DESC  ) as invoicedate
                FROM Sales.Invoices  as i
				INNER JOIN Sales.InvoiceLines  as il ON il.InvoiceID = i.InvoiceID
                WHERE i.CustomerID = C.CustomerID
                ORDER BY il.UnitPrice DESC ) AS inv
				--WHERE inv.CustomerID = 832
ORDER BY C.CustomerName, inv.StockItemID; -- сортировка для наглядности