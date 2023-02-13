/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
	  year(i.InvoiceDate)  as InvYear
	, month(i.InvoiceDate) as InvMonth
	, AVG(l.UnitPrice)	   as UnitPrice_AVG
	, SUM (l.UnitPrice*l.Quantity) as SaleSum
FROM Sales.Invoices as i
INNER JOIN Sales.InvoiceLines as l ON l.InvoiceID = i.InvoiceID 
GROUP BY   year(i.InvoiceDate) , month(i.InvoiceDate)
--ORDER BY year(i.InvoiceDate) , month(i.InvoiceDate)

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
Сортировка по году и месяцу.

*/

SELECT 
	  year(i.InvoiceDate)  as InvYear
	, month(i.InvoiceDate) as InvMonth
	, SUM (l.UnitPrice*l.Quantity) as SaleSum
FROM Sales.Invoices as i
INNER JOIN Sales.InvoiceLines as l ON l.InvoiceID = i.InvoiceID 
GROUP BY   year(i.InvoiceDate) , month(i.InvoiceDate)
HAVING  SUM (l.UnitPrice*l.Quantity) > 4600000
ORDER BY year(i.InvoiceDate) , month(i.InvoiceDate)

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
	  year(i.InvoiceDate)  as InvYear
	, month(i.InvoiceDate) as InvMonth
	, si.StockItemName
	, SUM (l.UnitPrice*l.Quantity) as SaleSum
	, MIN (i.InvoiceDate) as FirstSaleDate
	, SUM (l.Quantity) as SaleQty
FROM Sales.Invoices as i
INNER JOIN Sales.InvoiceLines as l ON l.InvoiceID = i.InvoiceID 
INNER JOIN Warehouse.StockItems as si ON si.StockItemID = l.StockItemID
GROUP BY   year(i.InvoiceDate) , month(i.InvoiceDate), si.StockItemName
HAVING  SUM (l.Quantity) < 50
ORDER BY year(i.InvoiceDate) , month(i.InvoiceDate)	, si.StockItemName

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
4. Написать второй запрос ("Отобразить все месяцы, где общая сумма продаж превысила 4 600 000") 
за период 2015 год так, чтобы месяц, в котором сумма продаж была меньше указанной суммы также отображался в результатах,
но в качестве суммы продаж было бы '-'.
Сортировка по году и месяцу.

Пример результата:
-----+-------+------------
Year | Month | SalesTotal
-----+-------+------------
2015 | 1     | -
2015 | 2     | -
2015 | 3     | -
2015 | 4     | 5073264.75
2015 | 5     | -
2015 | 6     | -
2015 | 7     | 5155672.00
2015 | 8     | -
2015 | 9     | 4662600.00
2015 | 10    | -
2015 | 11    | -
2015 | 12    | -

*/

--v1
SELECT 
	  year(i.InvoiceDate)  as InvYear
	, month(i.InvoiceDate) as InvMonth
	, '-' as SaleSum
FROM Sales.Invoices as i
INNER JOIN Sales.InvoiceLines as l ON l.InvoiceID = i.InvoiceID 
WHERE year(i.InvoiceDate) = 2015
GROUP BY   year(i.InvoiceDate) , month(i.InvoiceDate)
HAVING  SUM (l.UnitPrice*l.Quantity) <= 4600000
UNION ALL
SELECT 
	  year(i.InvoiceDate)  as InvYear
	, month(i.InvoiceDate) as InvMonth
	, CAST(SUM (l.UnitPrice*l.Quantity) as varchar) as SaleSum
FROM Sales.Invoices as i
INNER JOIN Sales.InvoiceLines as l ON l.InvoiceID = i.InvoiceID 
WHERE year(i.InvoiceDate) = 2015
GROUP BY   year(i.InvoiceDate) , month(i.InvoiceDate)
HAVING  SUM (l.UnitPrice*l.Quantity) > 4600000
ORDER BY year(i.InvoiceDate) , month(i.InvoiceDate)

--v2. Судя по общей стоимомсти в плане, лучше использовать этот вариант, если правильно понимаю
SELECT		
  InvYear
, InvMonth
, CASE WHEN SaleSum > 4600000 THEN Cast(SaleSum as varchar)
							  ELSE '-'
  END  as SaleSum
FROM ( 	SELECT
			  year(i.InvoiceDate)  as InvYear
			, month(i.InvoiceDate) as InvMonth
			, SUM (l.UnitPrice*l.Quantity) as SaleSum
		FROM Sales.Invoices as i
		INNER JOIN Sales.InvoiceLines as l ON l.InvoiceID = i.InvoiceID 
		WHERE year(i.InvoiceDate) = 2015
		GROUP BY   year(i.InvoiceDate) , month(i.InvoiceDate)
	) AS cal (InvYear, InvMonth, SaleSum)
ORDER BY InvYear, InvMonth