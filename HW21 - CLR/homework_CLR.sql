-- HOMEWORK CLR
-- ������������ ��������� ��� ���������� �� : http://maximus-sql-notes.blogspot.com/2011/11/clr-sqlclr.html

-- �������� CLR
EXEC sp_configure 'show advanced options' , '1';
GO
RECONFIGURE;
GO
EXEC sp_configure 'clr enabled' , '1'
EXEC sp_configure 'clr strict security', 0; -- ��� ��������� �������� = 0 ����� �������� ������ ��� �������� ������
GO
RECONFIGURE;
EXEC sp_configure 'show advanced options' , '0';
GO

-- ������ VS � ����� RegexpProject
-- ����������������� ������ RegexpProject.dll � ����� RegexpProject\RegexpProject\bin\Debug\

--  ��������� ���� ���������� ������� � ���� ������ �������� (����� ���� �� �������� ����� ����������� ���� ��->����������������->������)
USE Production
CREATE ASSEMBLY CLRFunctions
FROM 'C:\Users\user\source\repos\RegexpProject\RegexpProject\bin\Debug\RegexpProject.dll'
WITH PERMISSION_SET = SAFE; 
GO

-- ��������� ������������ ������
SELECT * FROM sys.assemblies as a
WHERE a.is_user_defined = 1; -- ���������������� ������
GO

-- ���������� ������� �� ������
CREATE FUNCTION dbo.fn_RegularChecker(@str NVARCHAR(100), @pattern NVARCHAR(100))  
RETURNS bit
AS EXTERNAL NAME [CLRFunctions].[RegexpProject.FunctionsCLR].IsMatch;
GO 

-- ������������� �������
-- �������� Email
-- ������ ���������� RAISERROR �� ������� �������, ��� �� ���� �� ������ �� :)
CREATE OR ALTER   PROCEDURE [dbo].[UpdEmailCounteragentSp]
 @CounteragentID int,
 @NewEmail as NVARCHAR(50)
AS
BEGIN
	DECLARE @pattern as NVARCHAR(100) = '^[A-Za-z0-9][A-Za-z0-9\.\-_]*[A-Za-z0-9]*@([A-Za-z0-9]+([A-Za-z0-9-]*[A-Za-z0-9]+)*\.)+[A-Za-z]*$' 
	IF dbo.fn_RegularChecker(@NewEmail,@pattern) = 0 
		BEGIN
			DECLARE @msg nvarchar(100) =  'The email is not valid. Check the email address'
			RAISERROR (@msg, 16, 1)
		END
	ELSE 
		BEGIN 
			UPDATE c
			SET c.Email = @NewEmail
			FROM Production.dbo.Counteragents as c
			WHERE c.CounteragentId = @CounteragentID
		END 
END
GO

-- ���������� � ���������� ����������� ������
EXEC [UpdEmailCounteragentSp] @CounteragentID = 1 , @NewEmail = 'ssfsmail.ru'
GO
-- �������� �������������� ���� ��������� ��� ������������� ������
--���������: 50000, �������: 16, ���������: 1, ���������: UpdEmailCounteragentSp, ������: 10 [������ ������ ������: 56]
--The email is not valid. Check the email address

-- ���������� � �������� ����������� ������
EXEC [UpdEmailCounteragentSp] @CounteragentID = 1 , @NewEmail = 'ssf@smail.ru'
GO
-- ����������� ������ �����, � ����������� �������
-- (��������� �����: 1) 