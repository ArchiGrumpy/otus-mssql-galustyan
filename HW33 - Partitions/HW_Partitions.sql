USE [Production];

--Создаём файловую группу
ALTER DATABASE [Production] ADD FILEGROUP [YearsData]
GO

--Добавляем файл БД
ALTER DATABASE [Production] ADD FILE 
( NAME = N'YearsData', FILENAME = N'D:\Test\MSSQL\Yearsdata.ndf' , 
SIZE = 1097152KB , FILEGROWTH = 65536KB ) TO FILEGROUP [YearsData]
GO

--Создаём функцию партиционирования по годам
CREATE PARTITION FUNCTION [fnYearsPartition](DATETIME) AS RANGE RIGHT FOR VALUES
('20130101','20140101','20150101','20160101', '20230101');																																																									
GO

--Партиционируем, используя созданную функцию
CREATE PARTITION SCHEME [schmYearsPartition] AS PARTITION [fnYearsPartition] 
ALL TO ([YearsData])
GO

--Так как будем использовать на существующей таблице, 
--удаляем кластерный индекс и создаём новый кластерный индекс с ключом секционирования
ALTER TABLE [dbo].[Opers] DROP CONSTRAINT [PK_Opers] WITH ( ONLINE = OFF )
GO

ALTER TABLE Production.dbo.Opers ADD CONSTRAINT PK_Opers
PRIMARY KEY CLUSTERED  (CreateDate, OperId)
 ON [schmYearsPartition]([CreateDate]);

-- Для запуска bcp проверяем включен ли xp_cmdshell?
-- Если нет, то включаем через системную хранимую процедуру sp_configure
SELECT *
FROM sys.configurations  c
WHERE c.name = 'xp_cmdshell'

--В нашем случае включен (value=1). Результат выборки ниже. Поэтому Дополнительных манипуляций не потребуется
--configuration_id	    name		 value	minimum	maximum	value_in_use			description				      is_dynamic	is_advanced
--16390				xp_cmdshell     	1		0		1		1		         Enable or disable command shell	  1		        1

-- Узнаём точное название нашего сервера. Понадобится для bcp
SELECT @@SERVERNAME

-- Заполняем нашу таблицу данными из таблицы Sales.InsvoiceLines
-- Выполним через bulk insert, т.к. в таблице Sales.InsvoiceLines нет поля с датой для секционирования

EXEC master..xp_cmdshell 'bcp "SELECT L.[InvoiceLineID], L.[InvoiceID], L.[StockItemID], L.[UnitPrice], L.[Quantity], I.[InvoiceDate] FROM [WideWorldImporters].Sales.Invoices AS I	JOIN [WideWorldImporters].Sales.InvoiceLines AS L ON I.InvoiceID = L.InvoiceID" queryout "D:\Test\MSSQL\InvoiceLines.txt" -T -w -t "@eu&$" -S GA\SQL2022'

-- Заливаем выгруженные данные в нашу партиционированную таблицу
DECLARE 
	@path VARCHAR(256),
	@FileName VARCHAR(256),
	@onlyScript BIT, 
	@query	nVARCHAR(MAX),
	@dbname VARCHAR(255),
	@batchsize INT
	
	SELECT @dbname = DB_NAME();
	SET @batchsize = 1000;
	SELECT @dbname

	/*******************************************************************/
	/*******************************************************************/
	/******Change for path and file name*******************************/
	SET @path = 'D:\Test\MSSQL\';
	SET @FileName = 'InvoiceLines.txt';
	/*******************************************************************/
	/*******************************************************************/
	/*******************************************************************/

	SET @onlyScript = 0;
	
	BEGIN TRY

		IF @FileName IS NOT NULL
		BEGIN
			SET @query = 'BULK INSERT ['+@dbname+'].[dbo].[Opers]
				   FROM "'+@path+@FileName+'"
				   WITH 
					 (
						BATCHSIZE = '+CAST(@batchsize AS VARCHAR(255))+', 
						DATAFILETYPE = ''widechar'',
						FIELDTERMINATOR = ''@eu&$'',
						ROWTERMINATOR =''\n'',
						KEEPNULLS,
						TABLOCK        
					  );'

			PRINT @query

			IF @onlyScript = 0
				EXEC sp_executesql @query 
			PRINT 'Bulk insert '+@FileName+' is done, current time '+CONVERT(VARCHAR, GETUTCDATE(),120);
		END;
	END TRY

	BEGIN CATCH
		SELECT   
			ERROR_NUMBER() AS ErrorNumber  
			,ERROR_MESSAGE() AS ErrorMessage; 

		PRINT 'ERROR in Bulk insert '+@FileName+' , current time '+CONVERT(VARCHAR, GETUTCDATE(),120);

	END CATCH

-- Смотрим распределение данных по партициям после загрузки данных
SELECT  $PARTITION.fnYearsPartition([CreateDate]) AS Partition
		, COUNT(*) AS [COUNT]
		, MIN([CreateDate]) as 'Left border'
		,MAX([CreateDate])  as 'Right border'
FROM [dbo].[Opers]
GROUP BY $PARTITION.fnYearsPartition([CreateDate]) 
ORDER BY Partition ;  

--Результат запроса:
--Partition	COUNT	Left border					Right border
--2			60968	2013-01-01 00:00:00.000		2013-12-31 00:00:00.000
--3			65941	2014-01-01 00:00:00.000		2014-12-31 00:00:00.000
--4			71898	2015-01-01 00:00:00.000		2015-12-31 00:00:00.000
--5			29458	2016-01-01 00:00:00.000		2016-05-31 00:00:00.000