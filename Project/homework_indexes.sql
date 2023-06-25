/*

Думаем какие запросы у вас будут в базе и добавляем для них индексы. Проверяем, что они используются в запросе. 

*/

-- создаем каталог для полнотекстовых индексов
USE [Production]
GO

CREATE FULLTEXT CATALOG [FullTextIndexes] WITH ACCENT_SENSITIVITY = ON
AS DEFAULT
AUTHORIZATION [dbo]
GO

-- Полнотекстовый поиск в таблице Counteragents по полю имя контрагента
CREATE FULLTEXT INDEX ON Counteragents(CounteragentName LANGUAGE Russian)
KEY INDEX PK_Counteragents 
ON ([FullTextIndexes])
WITH (
  CHANGE_TRACKING = AUTO, 
  STOPLIST = SYSTEM 
);
GO

-- Полнотекстовый поиск в таблице Products по полю наименование товара
CREATE FULLTEXT INDEX ON Products(ProductName LANGUAGE Russian)
KEY INDEX PK__tmp_ms_x__B40CC6CD94F56192 
ON ([FullTextIndexes])
WITH (
  CHANGE_TRACKING = AUTO, 
  STOPLIST = SYSTEM 
);
GO

-- Таблица содержит операции, кол-во записей большое, имеет смысл ваешать индекс на таблицу по столбцам, на которых "висят" внешние ключи
CREATE NONCLUSTERED INDEX [index_docid_productid] ON [dbo].[Opers]
(
	[DocID] ASC,
	[ProductID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

-- Таблица будет содержать большое кол-во транзакций, делаем индекс на поле с внешним ключом
-- отсеиваем NULL
CREATE NONCLUSTERED INDEX [Index_tranactions_docid] ON [dbo].[Transactions]
(
	[DocId] ASC
)
WHERE ([DocID] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

-- Таблица документов будет содержать много записей, поиск документов часто будет осуществляться по контрагенту, 
-- есть  смысл сделать индекс на это поле, являющееся внешни ключом
CREATE NONCLUSTERED INDEX [index_docs_counteragent] ON [dbo].[Docs]
(
	[CounteragentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

-- для аналитики  индекс COLUMNSTORE по сумме транзакции
CREATE NONCLUSTERED COLUMNSTORE INDEX [ColumnStoreIndex_TransSum] ON [dbo].[Transactions]
(
	[TransSum]
)WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0, DATA_COMPRESSION = COLUMNSTORE) ON [PRIMARY]
GO

-- Возможно, в процессе дальнешей разработки БД при создании запросов, ХП, функций и так далее будут добавлены новые или изменны текущие индексы



