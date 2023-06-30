-- Создаем базу-витрину
USE [master]
GO

/****** Object:  Database [ProductionDW]    Script Date: 08.05.2023 13:55:19 ******/
CREATE DATABASE [ProductionDW]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'ProductionDW', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\ProductionDW.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'ProductionDW_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\ProductionDW_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO

IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [ProductionDW].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO

ALTER DATABASE [ProductionDW] SET ANSI_NULL_DEFAULT OFF 
GO

ALTER DATABASE [ProductionDW] SET ANSI_NULLS OFF 
GO

ALTER DATABASE [ProductionDW] SET ANSI_PADDING OFF 
GO

ALTER DATABASE [ProductionDW] SET ANSI_WARNINGS OFF 
GO

ALTER DATABASE [ProductionDW] SET ARITHABORT OFF 
GO

ALTER DATABASE [ProductionDW] SET AUTO_CLOSE OFF 
GO

ALTER DATABASE [ProductionDW] SET AUTO_SHRINK OFF 
GO

ALTER DATABASE [ProductionDW] SET AUTO_UPDATE_STATISTICS ON 
GO

ALTER DATABASE [ProductionDW] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO

ALTER DATABASE [ProductionDW] SET CURSOR_DEFAULT  GLOBAL 
GO

ALTER DATABASE [ProductionDW] SET CONCAT_NULL_YIELDS_NULL OFF 
GO

ALTER DATABASE [ProductionDW] SET NUMERIC_ROUNDABORT OFF 
GO

ALTER DATABASE [ProductionDW] SET QUOTED_IDENTIFIER OFF 
GO

ALTER DATABASE [ProductionDW] SET RECURSIVE_TRIGGERS OFF 
GO

ALTER DATABASE [ProductionDW] SET  DISABLE_BROKER 
GO

ALTER DATABASE [ProductionDW] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO

ALTER DATABASE [ProductionDW] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO

ALTER DATABASE [ProductionDW] SET TRUSTWORTHY OFF 
GO

ALTER DATABASE [ProductionDW] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO

ALTER DATABASE [ProductionDW] SET PARAMETERIZATION SIMPLE 
GO

ALTER DATABASE [ProductionDW] SET READ_COMMITTED_SNAPSHOT OFF 
GO

ALTER DATABASE [ProductionDW] SET HONOR_BROKER_PRIORITY OFF 
GO

ALTER DATABASE [ProductionDW] SET RECOVERY FULL 
GO

ALTER DATABASE [ProductionDW] SET  MULTI_USER 
GO

ALTER DATABASE [ProductionDW] SET PAGE_VERIFY CHECKSUM  
GO

ALTER DATABASE [ProductionDW] SET DB_CHAINING OFF 
GO

ALTER DATABASE [ProductionDW] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO

ALTER DATABASE [ProductionDW] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO

ALTER DATABASE [ProductionDW] SET DELAYED_DURABILITY = DISABLED 
GO

ALTER DATABASE [ProductionDW] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO

ALTER DATABASE [ProductionDW] SET QUERY_STORE = ON
GO

ALTER DATABASE [ProductionDW] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO

ALTER DATABASE [ProductionDW] SET  READ_WRITE 
GO

-- Создаем схемы
USE [ProductionDW]
GO
/****** Object:  Schema [Fact]    Script Date: 08.05.2023 13:50:27 ******/
CREATE SCHEMA [Fact]
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Dimensional model fact tables' , @level0type=N'SCHEMA',@level0name=N'Fact'
GO


/****** Object:  Schema [Dimension]    Script Date: 08.05.2023 13:51:46 ******/
CREATE SCHEMA [Dimension]
GO

CREATE SCHEMA [Integration];  
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Dimensional model dimension tables' , @level0type=N'SCHEMA',@level0name=N'Dimension'
GO

-- Создаём функцию для заполнения дат
/****** Object:  UserDefinedFunction [Integration].[GenerateDateDimensionColumns]    Script Date: 26.06.2023 22:03:15 ******/
CREATE OR ALTER FUNCTION [Integration].[GenerateDateDimensionColumns](@Date date)
RETURNS TABLE
AS
RETURN SELECT @Date AS [Date],
              DAY(@Date) AS [Day Number],
              CAST(DATENAME(day, @Date) AS nvarchar(10)) AS [Day],
              CAST(DATENAME(month, @Date) AS nvarchar(10)) AS [Month],
              CAST(SUBSTRING(DATENAME(month, @Date), 1, 3) AS nvarchar(3)) AS [Short Month],
              MONTH(@Date) AS [Calendar Month Number],
              CAST(N'CY' + CAST(YEAR(@Date) AS nvarchar(4)) + N'-' + SUBSTRING(DATENAME(month, @Date), 1, 3) AS nvarchar(10)) AS [Calendar Month Label],
              YEAR(@Date) AS [Calendar Year],
              CAST(N'CY' + CAST(YEAR(@Date) AS nvarchar(4)) AS nvarchar(10)) AS [Calendar Year Label],
              CASE WHEN MONTH(@Date) IN (11, 12)
                   THEN MONTH(@Date) - 10
                   ELSE MONTH(@Date) + 2
              END AS [Fiscal Month Number],
              CAST(N'FY' + CAST(CASE WHEN MONTH(@Date) IN (11, 12)
                                     THEN YEAR(@Date) + 1
                                     ELSE YEAR(@Date)
                                END AS nvarchar(4)) + N'-' + SUBSTRING(DATENAME(month, @Date), 1, 3) AS nvarchar(20)) AS [Fiscal Month Label],
              CASE WHEN MONTH(@Date) IN (11, 12)
                   THEN YEAR(@Date) + 1
                   ELSE YEAR(@Date)
              END AS [Fiscal Year],
              CAST(N'FY' + CAST(CASE WHEN MONTH(@Date) IN (11, 12)
                                     THEN YEAR(@Date) + 1
                                     ELSE YEAR(@Date)
                                END AS nvarchar(4)) AS nvarchar(10)) AS [Fiscal Year Label],
              DATEPART(ISO_WEEK, @Date) AS [ISO Week Number];
GO

-- Создаём процедуру для заполнения дат
-- Если таблицы с датами не существует, то создаемы
/****** Object:  StoredProcedure [Integration].[PopulateDateDimensionForYear]    Script Date: 26.06.2023 21:56:04 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [Integration].[PopulateDateDimensionForYear]
@YearNumber int
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @DateCounter date = DATEFROMPARTS(@YearNumber, 1, 1);

    BEGIN TRY;

        BEGIN TRAN;

			IF OBJECT_ID('Dimension.Date', 'U') IS NULL
				BEGIN
					CREATE TABLE [Dimension].[Date](
					[Date] [date] NOT NULL,
					[Day Number] [int] NOT NULL,
					[Day] [nvarchar](10) NOT NULL,
					[Month] [nvarchar](10) NOT NULL,
					[Short Month] [nvarchar](3) NOT NULL,
					[Calendar Month Number] [int] NOT NULL,
					[Calendar Month Label] [nvarchar](20) NOT NULL,
					[Calendar Year] [int] NOT NULL,
					[Calendar Year Label] [nvarchar](10) NOT NULL,
					[Fiscal Month Number] [int] NOT NULL,
					[Fiscal Month Label] [nvarchar](20) NOT NULL,
					[Fiscal Year] [int] NOT NULL,
					[Fiscal Year Label] [nvarchar](10) NOT NULL,
					[ISO Week Number] [int] NOT NULL,
				 CONSTRAINT [PK_Dimension_Date] PRIMARY KEY CLUSTERED 
				(
					[Date] ASC
				)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON  [Primary]
				) ON  [Primary]

				EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'DW key for date dimension (actual date is used for key)' , @level0type=N'SCHEMA',@level0name=N'Dimension', @level1type=N'TABLE',@level1name=N'Date', @level2type=N'COLUMN',@level2name=N'Date'

				EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Day of the month' , @level0type=N'SCHEMA',@level0name=N'Dimension', @level1type=N'TABLE',@level1name=N'Date', @level2type=N'COLUMN',@level2name=N'Day Number'

				EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Day name' , @level0type=N'SCHEMA',@level0name=N'Dimension', @level1type=N'TABLE',@level1name=N'Date', @level2type=N'COLUMN',@level2name=N'Day'

				EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Month name (ie September)' , @level0type=N'SCHEMA',@level0name=N'Dimension', @level1type=N'TABLE',@level1name=N'Date', @level2type=N'COLUMN',@level2name=N'Month'

				EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Short month name (ie Sep)' , @level0type=N'SCHEMA',@level0name=N'Dimension', @level1type=N'TABLE',@level1name=N'Date', @level2type=N'COLUMN',@level2name=N'Short Month'

				EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Calendar month number' , @level0type=N'SCHEMA',@level0name=N'Dimension', @level1type=N'TABLE',@level1name=N'Date', @level2type=N'COLUMN',@level2name=N'Calendar Month Number'

				EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Calendar month label (ie CY2015Jun)' , @level0type=N'SCHEMA',@level0name=N'Dimension', @level1type=N'TABLE',@level1name=N'Date', @level2type=N'COLUMN',@level2name=N'Calendar Month Label'

				EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Calendar year (ie 2015)' , @level0type=N'SCHEMA',@level0name=N'Dimension', @level1type=N'TABLE',@level1name=N'Date', @level2type=N'COLUMN',@level2name=N'Calendar Year'

				EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Calendar year label (ie CY2015)' , @level0type=N'SCHEMA',@level0name=N'Dimension', @level1type=N'TABLE',@level1name=N'Date', @level2type=N'COLUMN',@level2name=N'Calendar Year Label'

				EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Fiscal month number' , @level0type=N'SCHEMA',@level0name=N'Dimension', @level1type=N'TABLE',@level1name=N'Date', @level2type=N'COLUMN',@level2name=N'Fiscal Month Number'

				EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Fiscal month label (ie FY2015Feb)' , @level0type=N'SCHEMA',@level0name=N'Dimension', @level1type=N'TABLE',@level1name=N'Date', @level2type=N'COLUMN',@level2name=N'Fiscal Month Label'

				EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Fiscal year (ie 2016)' , @level0type=N'SCHEMA',@level0name=N'Dimension', @level1type=N'TABLE',@level1name=N'Date', @level2type=N'COLUMN',@level2name=N'Fiscal Year'

				EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Fiscal year label (ie FY2015)' , @level0type=N'SCHEMA',@level0name=N'Dimension', @level1type=N'TABLE',@level1name=N'Date', @level2type=N'COLUMN',@level2name=N'Fiscal Year Label'

				EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'ISO week number (ie 25)' , @level0type=N'SCHEMA',@level0name=N'Dimension', @level1type=N'TABLE',@level1name=N'Date', @level2type=N'COLUMN',@level2name=N'ISO Week Number'

				EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Date dimension' , @level0type=N'SCHEMA',@level0name=N'Dimension', @level1type=N'TABLE',@level1name=N'Date'

			END

        WHILE YEAR(@DateCounter) = @YearNumber
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM Dimension.[Date] WHERE [Date] = @DateCounter)
            BEGIN
                INSERT Dimension.[Date]
                    ([Date], [Day Number], [Day], [Month], [Short Month],
                     [Calendar Month Number], [Calendar Month Label], [Calendar Year], [Calendar Year Label],
                     [Fiscal Month Number], [Fiscal Month Label], [Fiscal Year], [Fiscal Year Label],
                     [ISO Week Number])
                SELECT [Date], [Day Number], [Day], [Month], [Short Month],
                       [Calendar Month Number], [Calendar Month Label], [Calendar Year], [Calendar Year Label],
                       [Fiscal Month Number], [Fiscal Month Label], [Fiscal Year], [Fiscal Year Label],
                       [ISO Week Number]
                FROM Integration.GenerateDateDimensionColumns(@DateCounter);
            END;
            SET @DateCounter = DATEADD(day, 1, @DateCounter);
        END;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        PRINT N'Unable to populate dates for the year';
        THROW;
        RETURN -1;
    END CATCH;

    RETURN 0;
END;
GO

-- Заполнем даты 
   DECLARE @YearForPopulate int
   
   DECLARE year_cur CURSOR FOR 
    SELECT year([CreateDate]) YearForPopulate
	FROM [Production].[dbo].[Docs] as d
	GROUP BY year([CreateDate]) 
	ORDER BY YearForPopulate
   
   OPEN year_cur
   --считываем данные первой строки в наши переменные
   FETCH NEXT FROM year_cur INTO @YearForPopulate
   --если данные в курсоре есть, то заходим в цикл
   --и крутимся там до тех пор, пока не закончатся строки в курсоре
   WHILE @@FETCH_STATUS = 0
   BEGIN
		EXECUTE [Integration].[PopulateDateDimensionForYear] @YearForPopulate

        --считываем следующую строку курсора
        FETCH NEXT FROM year_cur INTO @YearForPopulate
   END
   
   CLOSE year_cur
   DEALLOCATE year_cur
   GO

--Создаем схему для последовательностей
CREATE SCHEMA [Sequences]
GO

--Создаем последовательность для таблицы [Dimension].[Counteragent]
/****** Object:  Sequence [Sequences].[CounteragentKey]    Script Date: 26.06.2023 23:20:33 ******/
CREATE SEQUENCE [Sequences].[CounteragentKey] 
 AS [int]
 START WITH 1
 INCREMENT BY 1
 MINVALUE -2147483648
 MAXVALUE 2147483647
 CACHE 
GO

--Создаем таблицу [Dimension].[Counteragent]
/****** Object:  Table [Dimension].[Counteragent]    Script Date: 26.06.2023 23:18:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Dimension].[Counteragent](
	[Counteragent Key] [int] NOT NULL,
	[Prod Counteragent ID] [int] NOT NULL,
	[CounteragentName] [nvarchar](150) NOT NULL,
	[CounteragentType] [int] NOT NULL,
	[Lineage Key] [int] NOT NULL,
 CONSTRAINT [PK_Dimension_Counteragent] PRIMARY KEY CLUSTERED 
(
	[Counteragent Key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [Primary]
) ON [Primary]
GO

ALTER TABLE [Dimension].[Counteragent] ADD  CONSTRAINT [DF_Dimension_Counteragent_Key]  DEFAULT (NEXT VALUE FOR [Sequences].[CounteragentKey]) FOR [Counteragent Key]
GO

-- Создаем последовательность для таблицы [Dimension].[Product]
/****** Object:  Sequence [Sequences].[ProductKey]    Script Date: 26.06.2023 23:42:13 ******/
CREATE SEQUENCE [Sequences].[ProductKey] 
 AS [int]
 START WITH 1
 INCREMENT BY 1
 MINVALUE -2147483648
 MAXVALUE 2147483647
 CACHE 
GO

--Создаем таблицу [Dimension].[Product]
/****** Object:  Table [Dimension].[Product]    Script Date: 26.06.2023 23:45:08 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Dimension].[Product]') AND type in (N'U'))
DROP TABLE [Dimension].[Product]
GO

/****** Object:  Table [Dimension].[Product]    Script Date: 26.06.2023 23:45:08 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Dimension].[Product](
	[Product Key] [int] NOT NULL,
	[Prod Product ID] [int] NOT NULL,
	[ProductName] [nvarchar](50) NOT NULL,
	[ProductExtName] [nvarchar](150) NULL,
	[DrawingNum] [nvarchar](25) NULL,
	[UMId] [int] NULL,
	[GrpId] [int] NULL,
	[Photo] [varbinary](max) NULL,
	[BrandID] [int] NULL,
 CONSTRAINT [PK_Dimension_Product] PRIMARY KEY CLUSTERED 
(
	[Product Key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [Dimension].[Product] ADD  CONSTRAINT [DF_Dimension_Product_Key]  DEFAULT (NEXT VALUE FOR [Sequences].[ProductKey]) FOR [Product Key]
GO

-- Создаме таблицу продаж
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Fact].[Sale]') AND type in (N'U'))
DROP TABLE [Fact].[Sale]
GO

/****** Object:  Table [Fact].[Sale]    Script Date: 27.06.2023 0:06:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [Fact].[Sale](
	[Sale Key] [bigint] IDENTITY(1,1) NOT NULL,
	[Counteragent Key] [int] NOT NULL,
	[Product Key] [int] NOT NULL,
	[DocDate Key] [date] NOT NULL,
	[Doc ID] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[Unit Price] [decimal](18, 2) NOT NULL,
	[Line Sum] [decimal](18, 3) NOT NULL,
 CONSTRAINT [PK_Fact_Sale] PRIMARY KEY CLUSTERED 
(
	[Sale Key] ASC,
	[DocDate Key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [Primary]
) ON [Primary]
GO


ALTER TABLE [Fact].[Sale]  WITH CHECK ADD  CONSTRAINT [FK_Fact_Sale_Counteragent_Key_Dimension_Counteragent] FOREIGN KEY([Counteragent Key])
REFERENCES [Dimension].[Counteragent] ([Counteragent Key])
GO

ALTER TABLE [Fact].[Sale] CHECK CONSTRAINT [FK_Fact_Sale_Counteragent_Key_Dimension_Counteragent]
GO

ALTER TABLE [Fact].[Sale]  WITH CHECK ADD  CONSTRAINT [FK_Fact_Sale_DocDate_Key_Dimension_Date] FOREIGN KEY([DocDate Key])
REFERENCES [Dimension].[Date] ([Date])
GO

ALTER TABLE [Fact].[Sale] CHECK CONSTRAINT [FK_Fact_Sale_DocDate_Key_Dimension_Date]
GO


ALTER TABLE [Fact].[Sale]  WITH CHECK ADD  CONSTRAINT [FK_Fact_Sale_Product_Key_Dimension_Product] FOREIGN KEY([Product Key])
REFERENCES [Dimension].[Product] ([Product Key])
GO

ALTER TABLE [Fact].[Sale] CHECK CONSTRAINT [FK_Fact_Sale_Product_Key_Dimension_Product]
GO


-- Вставка данных в витрину

-- Контрагенты
INSERT INTO [ProductionDW].[Dimension].[Counteragent]
(     --[Counteragent Key],  --вставляется последовательностью.
      [Prod Counteragent ID]
      ,[CounteragentName]
      ,[CounteragentType]
      ,[Lineage Key]
)
SELECT c.CounteragentId, c.CounteragentName, c.CounteragentType, 1 as [Lineage Key]
FROM [Production].[dbo].[Counteragents] as c
GO

-- Продукты
INSERT INTO [ProductionDW].[Dimension].[Product]
           (--[Product Key], --вставляется последовательностью.
		    [Prod Product ID]
           ,[ProductName]
           ,[ProductExtName]
           ,[Photo]
           ,[BrandID]
		   ,[Brand])
SELECT [ProductId]
      ,[ProductName]
      ,[ProductExtName]
      ,[Photo]
      ,p.[BrandID]
	  ,b.Brand
FROM [Production].[dbo].[Products] as p
LEFT JOIN [Production].[dbo].[Brands] as b ON b.BrandId = p.BrandID
GO

-- Строки продаж
INSERT INTO [Fact].[Sale]
           ([Counteragent Key]
           ,[Product Key]
           ,[DocDate Key]
           ,[Doc ID]
           ,[Quantity]
           ,[Unit Price]
           ,[Line Sum])
SELECT   cdw.[Counteragent Key]
		,pdw.[Product Key]
		,op.CreateDate
		,op.[DocID]  
		,[Quantity]
        ,[Price]
        ,[Quantity] * [Price] as [Line Sum]
FROM Production.dbo.Opers as op 
INNER JOIN Production.dbo.Docs as d On d.docid = op.docid
INNER JOIN [ProductionDW].[Dimension].[Counteragent] as cdw ON cdw.[Prod Counteragent ID] = d.CounteragentId
INNER JOIN [ProductionDW].[Dimension].[Product]		 as pdw ON pdw.[Prod Product ID] = op.ProductID
GO

