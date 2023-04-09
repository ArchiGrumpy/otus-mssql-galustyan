Начало проектной работы. 
Создание таблиц и представлений для своего проекта.

Нужно написать операторы DDL для создания БД вашего проекта:
1. Создать базу данных.
USE [master]
GO

/****** Object:  Database [Production]    Script Date: 25.03.2023 16:21:47 ******/
DROP DATABASE IF EXISTS [Production]
GO

/****** Object:  Database [Production]    Script Date: 25.03.2023 16:21:47 ******/
CREATE DATABASE [Production]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Production', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\Production.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Production_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL2022\MSSQL\DATA\Production_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO

IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Production].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO

ALTER DATABASE [Production] SET ANSI_NULL_DEFAULT ON 
GO

ALTER DATABASE [Production] SET ANSI_NULLS ON 
GO

ALTER DATABASE [Production] SET ANSI_PADDING ON 
GO

ALTER DATABASE [Production] SET ANSI_WARNINGS ON 
GO

ALTER DATABASE [Production] SET ARITHABORT ON 
GO

ALTER DATABASE [Production] SET AUTO_CLOSE OFF 
GO

ALTER DATABASE [Production] SET AUTO_SHRINK OFF 
GO

ALTER DATABASE [Production] SET AUTO_UPDATE_STATISTICS ON 
GO

ALTER DATABASE [Production] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO

ALTER DATABASE [Production] SET CURSOR_DEFAULT  LOCAL 
GO

ALTER DATABASE [Production] SET CONCAT_NULL_YIELDS_NULL ON 
GO

ALTER DATABASE [Production] SET NUMERIC_ROUNDABORT OFF 
GO

ALTER DATABASE [Production] SET QUOTED_IDENTIFIER ON 
GO

ALTER DATABASE [Production] SET RECURSIVE_TRIGGERS OFF 
GO

ALTER DATABASE [Production] SET  DISABLE_BROKER 
GO

ALTER DATABASE [Production] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO

ALTER DATABASE [Production] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO

ALTER DATABASE [Production] SET TRUSTWORTHY OFF 
GO

ALTER DATABASE [Production] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO

ALTER DATABASE [Production] SET PARAMETERIZATION SIMPLE 
GO

ALTER DATABASE [Production] SET READ_COMMITTED_SNAPSHOT OFF 
GO

ALTER DATABASE [Production] SET HONOR_BROKER_PRIORITY OFF 
GO

ALTER DATABASE [Production] SET RECOVERY FULL 
GO

ALTER DATABASE [Production] SET  MULTI_USER 
GO

ALTER DATABASE [Production] SET PAGE_VERIFY NONE  
GO

ALTER DATABASE [Production] SET DB_CHAINING OFF 
GO

ALTER DATABASE [Production] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO

ALTER DATABASE [Production] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO

ALTER DATABASE [Production] SET DELAYED_DURABILITY = DISABLED 
GO

ALTER DATABASE [Production] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO

ALTER DATABASE [Production] SET QUERY_STORE = OFF
GO

ALTER DATABASE [Production] SET  READ_WRITE 
GO

2. 3-4 основные таблицы для своего проекта. 

-- 1. Table Docs
USE [Production]
GO

/****** Object:  Table [dbo].[Docs]    Script Date: 25.03.2023 16:31:34 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Docs]') AND type in (N'U'))
DROP TABLE [dbo].[Docs]
GO

/****** Object:  Table [dbo].[Docs]    Script Date: 25.03.2023 16:31:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Docs](
	[DocId] [int] IDENTITY(1,1) NOT NULL,
	[Docname] [nvarchar](50) NOT NULL,
	[DocTypeID] [int] NOT NULL,
	[Comment] [nvarchar](50) NULL,
	[WarehouseId] [int] NOT NULL,
	[LocationID] [int] NULL,
	[CreateDate] [datetime] NOT NULL,
	[CounteragentId] [int] NOT NULL,
 CONSTRAINT [PK_Docs] PRIMARY KEY CLUSTERED 
(
	[DocId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- 2. Table Counteragents
USE [Production]
GO

/****** Object:  Table [dbo].[Counteragents]    Script Date: 25.03.2023 16:40:05 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Counteragents]') AND type in (N'U'))
DROP TABLE [dbo].[Counteragents]
GO

/****** Object:  Table [dbo].[Counteragents]    Script Date: 25.03.2023 16:40:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Counteragents](
	[CounteragentId] [int] IDENTITY(1,1) NOT NULL,
	[CounteragentName] [nvarchar](50) NOT NULL,
	[Address] [nvarchar](100) NULL,
	[Phone] [nvarchar](12) NULL,
	[CounteragentType] [int] NOT NULL,
	[BankInfo] [nvarchar](150) NULL,
	[Email] [nvarchar](50) NULL,
	[WebsiteURL] [nvarchar](50) NULL,
 CONSTRAINT [PK_Counteragents] PRIMARY KEY CLUSTERED 
(
	[CounteragentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- 3. Table DocTypes
USE [Production]
GO

EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'DocTypes'
GO

EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'DocTypes', @level2type=N'COLUMN',@level2name=N'OpSign'
GO

EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'DocTypes', @level2type=N'COLUMN',@level2name=N'DocType'
GO

ALTER TABLE [dbo].[DocTypes] DROP CONSTRAINT [DF_DocTypes_OpSign]
GO

/****** Object:  Table [dbo].[DocTypes]    Script Date: 25.03.2023 16:42:05 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DocTypes]') AND type in (N'U'))
DROP TABLE [dbo].[DocTypes]
GO

/****** Object:  Table [dbo].[DocTypes]    Script Date: 25.03.2023 16:42:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DocTypes](
	[DocTypeId] [int] IDENTITY(1,1) NOT NULL,
	[DocType] [nvarchar](20) NOT NULL,
	[OpSign] [nchar](10) NOT NULL,
 CONSTRAINT [PK_DocTypes] PRIMARY KEY CLUSTERED 
(
	[DocTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

-- 4. Table Warehouses
USE [Production]
GO

/****** Object:  Table [dbo].[Warehouses]    Script Date: 25.03.2023 16:51:49 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Warehouses]') AND type in (N'U'))
DROP TABLE [dbo].[Warehouses]
GO

/****** Object:  Table [dbo].[Warehouses]    Script Date: 25.03.2023 16:51:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Warehouses](
	[WarehouseId] [int] IDENTITY(1,1) NOT NULL,
	[Warehouse] [nvarchar](10) NOT NULL,
	[CreateDate] [datetime] NULL,
 CONSTRAINT [PK_Warehouses] PRIMARY KEY CLUSTERED 
(
	[WarehouseId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


3. Первичные и внешние ключи для всех созданных таблиц.

-- Первичные ключи созданы сразу при создании таблиц. Ниже создание внешних ключей.
-- 1. Table Docs
ALTER TABLE [dbo].[Docs]  WITH CHECK ADD  CONSTRAINT [FK_Docs_Counteragents] FOREIGN KEY([CounteragentId])
REFERENCES [dbo].[Counteragents] ([CounteragentId])
GO

ALTER TABLE [dbo].[Docs] CHECK CONSTRAINT [FK_Docs_Counteragents]
GO

ALTER TABLE [dbo].[Docs]  WITH CHECK ADD  CONSTRAINT [FK_Docs_DocTypes] FOREIGN KEY([DocTypeID])
REFERENCES [dbo].[DocTypes] ([DocTypeId])
GO

ALTER TABLE [dbo].[Docs] CHECK CONSTRAINT [FK_Docs_DocTypes]
GO

ALTER TABLE [dbo].[Docs]  WITH CHECK ADD  CONSTRAINT [FK_Docs_Warehouses] FOREIGN KEY([WarehouseId])
REFERENCES [dbo].[Warehouses] ([WarehouseId])
GO

ALTER TABLE [dbo].[Docs] CHECK CONSTRAINT [FK_Docs_Warehouses]
GO

4. 1-2 индекса на таблицы
-- 2 индекса на таблицу [Docs], где будет много записей ( остальные  - справочники, пока особого смысла нет)

USE [Production]
GO
-- I index
/****** Object:  Index [index_counteragentid]    Script Date: 25.03.2023 17:27:26 ******/
DROP INDEX IF EXISTS [index_counteragentid] ON [dbo].[Docs]
GO

/****** Object:  Index [index_counteragentid]    Script Date: 25.03.2023 17:27:26 ******/
CREATE NONCLUSTERED INDEX [index_counteragentid] ON [dbo].[Docs]
(
	[CounteragentId] ASC
)
INCLUDE([Docname],[DocTypeID],[Comment],[WarehouseId],[LocationID],[CreateDate]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

-- II index
USE [Production]
GO

/****** Object:  Index [index_counteragentid_where]    Script Date: 25.03.2023 17:31:24 ******/
DROP INDEX  IF EXISTS [index_counteragentid_where] ON [dbo].[Docs]
GO

/****** Object:  Index [index_counteragentid_where]    Script Date: 25.03.2023 17:31:24 ******/
CREATE NONCLUSTERED INDEX [index_counteragentid_where] ON [dbo].[Docs]
(
	[DocTypeID] ASC,
	[WarehouseId] ASC,
	[LocationID] ASC,
	[CreateDate] ASC,
	[CounteragentId] ASC
)
INCLUDE([Docname],[Comment]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

5. Наложите по одному ограничению в каждой таблице на ввод данных.
-- По одному default и ограничению на каждую таблицу
-- 1. Table Docs
ALTER TABLE [dbo].[Docs] ADD  CONSTRAINT [DF_Docs_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[Docs] ADD CONSTRAINT [CHECK_Docs_CreateDate] CHECK (datediff(yy, [CreateDate], getdate()) <=1);
GO
-- 2. Table Counteragents
ALTER TABLE [dbo].[Counteragents] ADD  CONSTRAINT [DF_Counteragents_CounteragentType]  DEFAULT ((0)) FOR [CounteragentType]
GO
ALTER TABLE [dbo].[Counteragents] ADD CONSTRAINT [CHECK_Counteragents_CounteragentType] CHECK ( [CounteragentType]>=0);
GO
-- 3. Table DocTypes
ALTER TABLE [dbo].[DocTypes] ADD  CONSTRAINT [DF_DocTypes_OpSign]  DEFAULT ((0)) FOR [OpSign]
GO
ALTER TABLE [dbo].[DocTypes] ADD CONSTRAINT [CHECK_DocTypes_OpSign] CHECK ( [OpSign] between -1 AND 1);
GO
-- 4. Table Warehouses
ALTER TABLE [dbo].[Warehouses] ADD  CONSTRAINT [DF_Warehouses_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[Warehouses] ADD CONSTRAINT [CHECK_Warehouses_CreateDate] CHECK (datediff(yy, [CreateDate], getdate()) <=1);
GO
