CREATE PROCEDURE [dbo].syncNewData 
AS
Begin
DECLARE @lastLoadDate datetime
DECLARE @currentDate datetime
DECLARE @contactRecordCount int
DECLARE @paymentsRecordCount int
DECLARE @ticketsRecordCount int
SET @currentDate =  GETDATE()
SET @lastLoadDate = (Select max(eveventdate) from temptickets)
IF @lastLoadDate IS NULL
BEGIN
EXEC [dbo].decofc_createtempticketstosync '2016-02-01',@currentDate
EXEC [dbo].ReformatNewData '2016-02-01',@currentDate
END
ELSE
BEGIN
EXEC [dbo].decofc_createtempticketstosync @lastLoadDate,@currentDate
EXEC [dbo].ReformatNewData @lastLoadDate,@currentDate
END
SET @contactRecordCount=(Select count(*) from contacts_temp)
SET @paymentsRecordCount=(Select count(*) from payments_temp)
SET @ticketsRecordCount=(Select count(*) from tickets_temp)
IF @contactRecordCount>0
EXEC [dbo].LoadData 'dbo.contacts'
IF @paymentsRecordCount>0
EXEC [dbo].LoadData 'dbo.payments'
IF @ticketsRecordCount>0
EXEC [dbo].LoadData 'dbo.tickets'
end