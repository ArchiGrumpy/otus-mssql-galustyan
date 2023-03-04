/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

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

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/

DECLARE @sqltext nvarchar (max)
DECLARE @ColumnmNames nvarchar(max)

SELECT @ColumnmNames =  STRING_AGG (CONVERT(NVARCHAR(max),QUOTENAME(CustomerName)), ', ') 
										FROM
										(SELECT distinct  c.CustomerName as CustomerName
										FROM Sales.Invoices AS i
										INNER JOIN Sales.Customers as c ON c.CustomerID = i.CustomerID
										) as t										
SET @sqltext = 
N'
;WITH cte as 
(
SELECT	DATEADD(month, DATEDIFF(month, 0, i.InvoiceDate), 0)  as InvoiceMonth
		, c. CustomerName
		, COUNT (i.InvoiceID) as SalesCount
	 FROM Sales.Invoices AS i
	 INNER JOIN Sales.Customers as c ON c.CustomerID = i.CustomerID
	 GROUP BY DATEADD(month, DATEDIFF(month, 0, i.InvoiceDate), 0)  , c.CustomerName
)
SELECT FORMAT(InvoiceMonth, ''01.MM.yyyy'') as InvoiceMonth , ' + @ColumnmNames + '
FROM 
	( 	SELECT  * FROM cte 		
	) AS s
PIVOT (MAX(s.SalesCount) 
FOR CustomerName  IN (' + @ColumnmNames + ')
	)as PVT
ORDER BY PVT.InvoiceMonth 
'

EXECUTE sp_executesql @sqltext