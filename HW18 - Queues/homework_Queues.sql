-- ��� �������� 
select name, is_broker_enabled
from sys.databases;

SELECT * FROM sys.service_contract_message_usages; 
SELECT * FROM sys.service_contract_usages;
SELECT * FROM sys.service_queue_usages;
 
SELECT * FROM sys.transmission_queue;

SELECT * 
FROM dbo.InitiatorQueueProd;

SELECT * 
FROM dbo.TargetQueueProd;


SELECT conversation_handle, is_initiator, s.name as 'local service', 
far_service, sc.name 'contract', ce.state_desc
FROM sys.conversation_endpoints ce
LEFT JOIN sys.services s
ON ce.service_id = s.service_id
LEFT JOIN sys.service_contracts sc
ON ce.service_contract_id = sc.service_contract_id
ORDER BY conversation_handle;

-- �������� Service Broker
USE master
ALTER DATABASE Production
SET ENABLE_BROKER  WITH ROLLBACK IMMEDIATE; 

-- ������� ���� ���������
USE Production
-- For Request
CREATE MESSAGE TYPE
[//Prod/SB/RequestMessage]
VALIDATION=WELL_FORMED_XML;
-- For Reply
CREATE MESSAGE TYPE
[//Prod/SB/ReplyMessage]
VALIDATION=WELL_FORMED_XML; 
GO

-- ������� ��������
CREATE CONTRACT [//Prod/SB/Contract]
      ([//Prod/SB/RequestMessage]
         SENT BY INITIATOR,
       [//Prod/SB/ReplyMessage]
         SENT BY TARGET
      );
GO

-- ������� ������� � ������ ��� ���������� � ����
CREATE QUEUE TargetQueueProd;

CREATE SERVICE [//Prod/SB/TargetService]
       ON QUEUE TargetQueueProd
       ([//Prod/SB/Contract]);
GO


CREATE QUEUE InitiatorQueueProd;

CREATE SERVICE [//Prod/SB/InitiatorService]
       ON QUEUE InitiatorQueueProd
       ([//Prod/SB/Contract]);
GO

-- ������� ��������� �������� ���������
CREATE OR ALTER  PROCEDURE SendNewTransaction
	@TransId INT
AS
BEGIN
	SET NOCOUNT ON;

    --Sending a Request Message to the Target	
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
	DECLARE @RequestMessage NVARCHAR(4000);
	
	BEGIN TRAN 

	--Prepare the Message
	SELECT @RequestMessage = (SELECT tr.TransId
							  FROM Transactions AS tr
							  WHERE TransId = @TransId
							  FOR XML AUTO, root('RequestMessage')); 
	
	--Determine the Initiator Service, Target Service and the Contract 
	BEGIN DIALOG @InitDlgHandle
	FROM SERVICE
	[//Prod/SB/InitiatorService]
	TO SERVICE
	'//Prod/SB/TargetService'
	ON CONTRACT
	[//Prod/SB/Contract]
	WITH ENCRYPTION=OFF; 

	--Send the Message
	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE
	[//Prod/SB/RequestMessage]
	(@RequestMessage);
	
	--SELECT @RequestMessage AS SentRequestMessage; ������ ��� �������. ������� �� �����
	
	COMMIT TRAN 
END
GO

-- ��������� ����, ��������������� � ��������� �������
ALTER TABLE Transactions
ADD  TransactionConfirmedForProcessing DATETIME
	,TransactionStatus int DEFAULT (0) ;
GO

-- ������ ������������� ���������
CREATE OR ALTER  PROCEDURE GetNewTransaction
AS
BEGIN

	DECLARE @TargetDlgHandle UNIQUEIDENTIFIER,
			@Message NVARCHAR(4000),
			@MessageType Sysname,
			@ReplyMessage NVARCHAR(4000),
			@ReplyMessageName Sysname,
			@TransId INT,
			@xml XML; 
	
	BEGIN TRAN; 

	--Receive message from Initiator
	RECEIVE TOP(1)
		@TargetDlgHandle = Conversation_Handle,
		@Message = Message_Body,
		@MessageType = Message_Type_Name
	FROM dbo.TargetQueueProd; 

	-- SELECT @Message; -- ������ ��� �������.

	SET @xml = CAST(@Message AS XML);

	SELECT @TransId = R.Iv.value('@TransId','INT')
	FROM @xml.nodes('/RequestMessage/tr') as R(Iv);

	IF EXISTS (SELECT * FROM Transactions WHERE TransId = @TransId)
	BEGIN
		UPDATE tr
		SET  tr.TransactionConfirmedForProcessing = GETUTCDATE()
			,tr.TransactionStatus = 1 -- NEW
		FROM Transactions as tr
		WHERE tr.TransId = @TransId;
	END;
	
	-- SELECT @Message AS ReceivedRequestMessage, @MessageType;  -- ������ ��� �������.
	
	-- Confirm and Send a reply
	IF @MessageType=N'//Prod/SB/RequestMessage'
	BEGIN
		SET @ReplyMessage =N'<ReplyMessage> Message received</ReplyMessage>'; 
	
		SEND ON CONVERSATION @TargetDlgHandle
		MESSAGE TYPE
		[//Prod/SB/ReplyMessage]
		(@ReplyMessage);
		END CONVERSATION @TargetDlgHandle;
	END 
	
	-- SELECT @ReplyMessage AS SentReplyMessage;  - ������ ��� �������.

	COMMIT TRAN;
END
GO
-- ������ ������������� ���������
-- ��������� ������������ �������� ���������
CREATE OR ALTER PROCEDURE ConfirmTransaction
AS
BEGIN
	--Receiving Reply Message from the Target.	
	DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER,
			@ReplyReceivedMessage NVARCHAR(1000) 
	
	BEGIN TRAN; 

		RECEIVE TOP(1)
			@InitiatorReplyDlgHandle=Conversation_Handle
			,@ReplyReceivedMessage=Message_Body
		FROM dbo.InitiatorQueuProd; 
		
		END CONVERSATION @InitiatorReplyDlgHandle; 
		
		-- SELECT @ReplyReceivedMessage AS ReceivedRepliedMessage;  - ������ ��� �������.

	COMMIT TRAN; 
END
GO 

-- �������� �������� ��������
ALTER QUEUE [dbo].[InitiatorQueueProd] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF) 
	, ACTIVATION (   STATUS = ON ,
        PROCEDURE_NAME = ConfirmTransaction, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER) ; 

GO
ALTER QUEUE [dbo].[TargetQueueProd] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF)
	, ACTIVATION (  STATUS = ON ,
        PROCEDURE_NAME = GetNewTransaction, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER) ; 

GO

--  ��� ����� 
EXEC SendNewTransaction @TransId = 7 -- ��� ������� ���� ����� :)
GO