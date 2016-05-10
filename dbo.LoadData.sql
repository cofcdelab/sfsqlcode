CREATE PROCEDURE [dbo].LoadData @TableName varchar(255)
AS
DECLARE @MyXML XML 
DECLARE @xmlString VARCHAR(max)
Declare @request VARCHAR(max)	
Declare @count int	
Declare @startRow int
Declare @url VARCHAR(max)
Declare @response VARCHAR(max)
Declare @body VARCHAR(max) 
----------- tickets----------------------------
IF @TableName='dbo.tickets'
Begin
SET @request='/services/apexrest/MultiTicket'
SET @count=(SELECT count(*) from tickets_temp)
SET @startRow=1
WHILE @count>0
BEGIN   
   SET @MyXML=(SELECT tickid as External_TicketID__c,pricetypeid as PriceType__c,price as Price__c,evEventDate as Date_Time__c,Activity as Activity__c,userid as User__c,contactid as Contact__c,qty as Quantity__c,status as Status__c,guideid as Guide__c,fees as Fees__c,paymentid as Payment__c,last_transact_no as Last_Transaction_No__c from tickets_temp where tickid IN
   (SELECT tickid
   FROM 
   (
    SELECT tickid, ROW_NUMBER() OVER (ORDER BY tickid) AS RowNum 
    FROM tickets_temp
   ) sub
   WHERE sub.RowNum BETWEEN @startRow AND @startRow+99) FOR
   XML PATH('tickets'),TYPE)
   SELECT @MyXML
  
   SET @startRow=@startRow+100
   SET @count= @count-100
    
   SET @xmlString = cast(@MyXML as nvarchar(max))
   SET @body='<request><req>'+@xmlString+'</req></request>'
   SELECT @body
   SET @response=dbo.SF_RestPost(@request,@body)
   SELECT @response
END 
End
-------------------------Payments---------------------------------------
IF @TableName='dbo.payments'
Begin
SET @request='/services/apexrest/MultiPayment'
SET @count=(SELECT count(*) from payments_temp)
SET @startRow=1
WHILE @count>0
BEGIN   
 	SET @MyXML=(SELECT paymentid as External_Pay__c,type as Type__c,trandate as TransactionDate__c,mode as Mode__c,last_transact_no as Transaction_Number__c,lastCardNum as Card__c,lastcardName as Cardholder_Name__c,amount as Amount__c from payments_temp where paymentid IN
   (SELECT paymentid
   FROM 
   (
    SELECT paymentid, ROW_NUMBER() OVER (ORDER BY paymentid) AS RowNum 
    FROM payments_temp
   ) sub
   WHERE sub.RowNum BETWEEN @startRow AND @startRow+99) FOR
   XML PATH('payments'),TYPE)
   SELECT @MyXML
   SET @startRow=@startRow+100
   SET @count= @count-100
   SET @xmlString = cast(@MyXML as nvarchar(max))
   SET @body='<request><req>'+@xmlString+'</req></request>'
   SELECT @body
   SET @response=dbo.SF_RestPost(@request,@body)
   SELECT @response
END 
End

--------------------------Contacts------------------------------------------
IF @TableName='dbo.contacts'
Begin
SET @request='/services/apexrest/MultiContact'
SET @count=(SELECT count(*) from contacts_temp)
SET @startRow=1
WHILE @count>0
BEGIN   
   SET @MyXML=(SELECT cltcode as ExternalCID__c,cltfirstname as FirstName, cltSurName as LastName,cltEmail as Email from contacts_temp where cltcode IN
   (SELECT cltcode
   FROM 
   (
    SELECT cltcode, ROW_NUMBER() OVER (ORDER BY cltcode) AS RowNum 
    FROM contacts_temp
   ) sub
   WHERE sub.RowNum BETWEEN @startRow AND @startRow+99) FOR
   XML PATH('contacts'),TYPE)
   SELECT @MyXML
   SET @startRow=@startRow+100
   SET @count= @count-100
   SET @xmlString = cast(@MyXML as nvarchar(max))
   SET @body='<request><req>'+@xmlString+'</req></request>'
   SELECT @body
   SET @response=dbo.SF_RestPost(@request,@body)
   SELECT @response
END 
End