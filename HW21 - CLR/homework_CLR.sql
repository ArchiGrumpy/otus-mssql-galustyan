-- HOMEWORK CLR
-- Используемые источники для выполнения ДЗ : http://maximus-sql-notes.blogspot.com/2011/11/clr-sqlclr.html

-- Включаем CLR
EXEC sp_configure 'show advanced options' , '1';
GO
RECONFIGURE;
GO
EXEC sp_configure 'clr enabled' , '1'
EXEC sp_configure 'clr strict security', 0; -- Без установки значения = 0 этого атрибута ошибка при создании сборки
GO
RECONFIGURE;
EXEC sp_configure 'show advanced options' , '0';
GO

-- Проект VS в папке RegexpProject
-- Откомпилированная сборка RegexpProject.dll в папке RegexpProject\RegexpProject\bin\Debug\

--  Добавляем нашу библиотеку сборкой в базу данных скриптом (можно было бы добавить через контекстное меню БД->Программирование->Сборки)
USE Production
CREATE ASSEMBLY CLRFunctions
FROM 'C:\Users\user\source\repos\RegexpProject\RegexpProject\bin\Debug\RegexpProject.dll'
WITH PERMISSION_SET = SAFE; 
GO

-- Проверяем подключенные сборки
SELECT * FROM sys.assemblies as a
WHERE a.is_user_defined = 1; -- пользовательские сборки
GO

-- Подключаем функцию из сборки
CREATE FUNCTION dbo.fn_RegularChecker(@str NVARCHAR(100), @pattern NVARCHAR(100))  
RETURNS bit
AS EXTERNAL NAME [CLRFunctions].[RegexpProject.FunctionsCLR].IsMatch;
GO 

-- Использование функции
-- Проверка Email
-- Заодно используем RAISERROR из другого занятия, раз по нему не задано ДЗ :)
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

-- Используем с невалидной электронной почтой
EXEC [UpdEmailCounteragentSp] @CounteragentID = 1 , @NewEmail = 'ssfsmail.ru'
GO
-- получаем сформированное нами сообщение при возникновении ошибки
--сообщение: 50000, уровень: 16, состояние: 1, процедура: UpdEmailCounteragentSp, строка: 10 [строка начала пакета: 56]
--The email is not valid. Check the email address

-- Используем с валидной электронной почтой
EXEC [UpdEmailCounteragentSp] @CounteragentID = 1 , @NewEmail = 'ssf@smail.ru'
GO
-- срабатывает вторая ветка, с обновлением таблицы
-- (затронуто строк: 1) 