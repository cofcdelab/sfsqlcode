CREATE PROCEDURE [dbo].syncNewData 
AS
Begin
DECLARE @lastLoadDate datetime
DECLARE @currentDate datetime
SET @currentDate =  GETDATE()
SET @lastLoadDate = (Select max(eveventdate) from temptickets)
IF @lastLoadDate IS NULL
BEGIN
EXEC [dbo].decofc_createtempticketstosync '2000-01-01', @currentDate
EXEC [dbo].ReformatNewData '2000-01-01', @currentDate
END
ELSE
BEGIN
EXEC [dbo].decofc_createtempticketstosync @lastLoadDate, @currentDate
EXEC [dbo].ReformatNewData @lastLoadDate, @currentDate
END
EXEC [dbo].LoadData 'dbo.contacts'
EXEC [dbo].LoadData 'dbo.payments'
EXEC [dbo].LoadData 'dbo.tickets'
end