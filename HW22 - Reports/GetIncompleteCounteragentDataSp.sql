USE [Production]
GO

/****** Object:  StoredProcedure [dbo].[UpdEmailCounteragentSp]    Script Date: 30.04.2023 19:34:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER     PROCEDURE [dbo].[GetIncompleteCounteragentDataSp]
AS
BEGIN
	SELECT [CounteragentName], [Address], [Phone]
	, 	Case [CounteragentType] WHEN 1 then 'Supplier' END  as CounteragentType
	, [BankInfo], [Email], [WebsiteURL]
	FROM Production.dbo.Counteragents as c
	WHERE c.Address    IS NULL
	   OR c.Phone      IS NULL
	   OR [BankInfo]   IS NULL
	   OR [Email]      IS NULL 
	   OR [WebsiteURL] IS NULL
END
GO


