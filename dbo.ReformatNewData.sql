CREATE PROCEDURE [dbo].ReformatNewData @startdate datetime, @enddate datetime 
AS
Begin
DECLARE @lastLoadDate datetime
-- This query generates the data for the contacts table
IF EXISTS (SELECT * FROM PEGettysburg2.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'contacts_temp')
drop table contacts_temp
select cltcode, cltfirstname, cltSurName,cltEmail into contacts_temp
from clients where cltcode in 
(select distinct timailinglist from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
where eveventdate between @startdate and @enddate)


IF EXISTS (SELECT * FROM PEGettysburg2.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'tickets_temp')
drop table tickets_temp
select minticode tickid, tipricetype pricetypeid, tiFullPrice price,evEventDate,shcode Activity,tilcode userid,tiMailingList contactid,count(*) qty, 
case when tistatus = 9 then 'Return' else 'Sale' end status, guideid+1000 guideid, fees,case when paymentid = 0 then null else paymentid end paymentid, max(titransactnum) last_transact_no 
into tickets_temp
from temptickets
group by minticode, tipricetype, tiFullPrice,evEventDate,shcode,tilcode,tiMailingList,tistatus,guideid, fees,paymentid 


IF EXISTS (SELECT * FROM PEGettysburg2.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'payments_temp')
drop table payments_temp
select paymentid, 
ptdescr type, rcbshiftdate trandate, case when rcbcachinout = 1 then 'Refund' else 'Receipt' end mode,max(titransactnum) last_transact_no, 
max(isnull(rccCreditNum,'')) lastCardNum, max(dbo.asc_xmlgetattribute('card_name',rccparamsdata)) lastCardName,
(select sum(rcbpayamount) from recieptbase r 
where rcbtransactnum in
(select t2.titransactnum from temptickets t2  
where t2.paymentid = t.paymentid)) amount into payments_temp
from 
temptickets t
left outer join recieptcredit on rcccode = paymentid
where paymentid > 0
group by paymentid,timailinglist,ptdescr,rcbshiftdate, rcbcachinout

END