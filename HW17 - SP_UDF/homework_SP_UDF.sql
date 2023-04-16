/*
	Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

-- Создаем 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Galustyan Arthur>
-- Create date: <15.04.2023>
-- Description:	<Функция возвращающает Клиента с наибольшей суммой покупки>
-- =============================================
CREATE OR ALTER FUNCTION udf_GetCustomer_forMaxInvSum
(
)
RETURNS int 
AS
BEGIN
	-- В задании не указано что выводить, выводим ID,  при необходимости можно вывести другую информацию, например, имя - CustomerName
	DECLARE @Customer int

	SELECT top 1 @Customer =  s.CustomerID
	FROM   Sales.Customers as s 
	INNER JOIN 	Sales.Invoices as i ON i.CustomerID = s.CustomerID
	INNER JOIN  Sales.InvoiceLines as il ON il.InvoiceID = i.InvoiceID
	GROUP BY  s.CustomerID, i.InvoiceID
	ORDER BY   SUM(il.Quantity*il.UnitPrice)  desc

	RETURN  @Customer

END
GO

-- Используем
SELECT dbo.udf_GetCustomer_forMaxInvSum();
GO

/*
	Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
*/

-- Создаем 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Galustyan Arthur>
-- Create date: <15.04.2023>
-- Description:	<Хранимая процедура выводит сумму покупки по клиенту>
-- =============================================
CREATE OR ALTER PROCEDURE sp_GetInvSum_forCustomer

@CustomerID int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT s.CustomerID , i.InvoiceID , SUM(il.Quantity*il.UnitPrice) as InvSum
	FROM   Sales.Customers as s 
	INNER JOIN 	Sales.Invoices as i ON i.CustomerID = s.CustomerID
	INNER JOIN  Sales.InvoiceLines as il ON il.InvoiceID = i.InvoiceID
	WHERE  s.CustomerID = @CustomerID
	GROUP BY  s.CustomerID, i.InvoiceID
END
GO

-- Используем
EXEC sp_GetInvSum_forCustomer @CustomerID = 834
GO

/*
	Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

-- Создаем функцию
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Galustyan Arthur>
-- Create date: <15.04.2023>
-- Description:	<Функция возвращает максимальную температуру выбранного сенсора за весь период данных в БД>
-- =============================================
CREATE OR ALTER FUNCTION udf_GetMaxTemperature
(
@ColdRoomSensorNumber int
)
RETURNS decimal(10,2) 
AS
BEGIN
	DECLARE @MaxTemperature  decimal(10,2) 
	--SET NOCOUNT ON - нельзя использовать в функции

	SELECT @MaxTemperature =  Max([Temperature]) 
	  FROM [WideWorldImporters].[Warehouse].[ColdRoomTemperatures]
	  FOR SYSTEM_TIME  ALL  as ct
	  WHERE ct.[ColdRoomSensorNumber] = @ColdRoomSensorNumber
	  

	RETURN  @MaxTemperature

END
GO

-- Создаем процедуру с той же функциональностью, что и функция  dbo.udf_GetMaxTemperature();
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Galustyan Arthur>
-- Create date: <15.04.2023>
-- Description:	<Хранимая процедура выводит возвращает максимальную температуру выбранного сенсора за весь период данных в БД>
-- =============================================
CREATE OR ALTER PROCEDURE sp_GetMaxTemperature
@ColdRoomSensorNumber int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON; -- можно закомментировать для чистоты эскперимента - результат будет точно таким же по плану

	  SELECT Max([Temperature]) 
	  FROM [WideWorldImporters].[Warehouse].[ColdRoomTemperatures]
	  FOR SYSTEM_TIME  ALL  as ct
	  WHERE ct.[ColdRoomSensorNumber] = @ColdRoomSensorNumber
END
GO

-- Выполняем функцию и процедуру, предварительно включив действительный план выполнения
SELECT dbo.udf_GetMaxTemperature(1);
GO
EXEC sp_GetMaxTemperature @ColdRoomSensorNumber = 1
GO

-- Файл плана прикладываю - Plan_UDF_vs_SP.sqlplan
-- Из плана видно, что функция по производительности выигрывает и выигрывает "всухую"
-- Функции заточены для выполнения агрегаций, поэтому ей требуется минимальные ресурсы для вычисления скалярного значения,
-- в отличие от процедуры, которой помимо расчета агрегата требуется индекс на архивной таблице,
-- а также дополнительные расходы на соединение, подсчет агрегатов в параллельных потоках и сборку параллельных потоков

/*
	Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла.
*/
-- Функция возвращает top (N) самых дорогих покупок для заказчика
-- Создаем
CREATE OR ALTER FUNCTION tvf_MaxInvSumForCustomers(
	@CustomerID int,
	@MaximumRowsToReturn int
)
RETURNS TABLE 
AS
	RETURN
	SELECT TOP(@MaximumRowsToReturn)
			   s.CustomerID 
			 , i.InvoiceID 
			 , SUM(il.Quantity*il.UnitPrice) as InvSum
	FROM   Sales.Customers as s 
	INNER JOIN 	Sales.Invoices as i ON i.CustomerID = s.CustomerID
	INNER JOIN  Sales.InvoiceLines as il ON il.InvoiceID = i.InvoiceID
	WHERE  s.CustomerID = @CustomerID
	GROUP BY  s.CustomerID, i.InvoiceID
	ORDER BY   InvSum  desc;
GO

-- Используем, вызов для каждой строки result set'а без использования цикла
SELECT s.CustomerID , s.CustomerName, tf.*
FROM Sales.Customers as s 
CROSS APPLY dbo.tvf_MaxInvSumForCustomers (s.CustomerID, 10) as tf

/*
	Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/

 -- Использовал бы READ COMMITTED. 
 -- Почему? Потому что этот уровень изоляции  определяет, что транзакция в текущем сеансе не может читать данные, модифицированные другой транзакцией, тем самым предотвращая грязное чтение.