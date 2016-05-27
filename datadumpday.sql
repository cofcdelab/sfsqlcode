declare @startdate datetime 
SET @startdate = '2014-10-01'
declare @enddate datetime 
SET @enddate = '2014-10-01 23:59'

IF EXISTS (SELECT * FROM gettysburgstagingday.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'contacts')
	drop table gettysburgstagingday..contacts

select cltcode, cltfirstname, cltSurName,cltEmail into gettysburgstagingday..contacts
from clients where cltcode in 
(select distinct timailinglist from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
where eveventdate between @startdate and @enddate)

/*
-- This query generates the data for the users table
select tilcode userid, tildescr username from till where tilcode in
(select distinct tilcode from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
where eveventdate between @startdate and @enddate)

-- This query generates the data for the guides table
select gdrcode+1000 guideid,gdrfirstname + ' ' + gdrlastname guidename from guiders
*/

IF EXISTS (SELECT * FROM gettysburgstagingday.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'pricetypes')
drop table gettysburgstagingday..pricetypes 
-- This query generates the data for the pricetype table
select pctcode pricetypeid, pctdescr description into gettysburgstagingday..pricetypes from PriceType where pctcode in
(select distinct tipricetype from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
where eveventdate between @startdate and @enddate)


IF EXISTS (SELECT * FROM gettysburgstagingday.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'activities')
drop table gettysburgstagingday..activities 
-- This query generates the data for the shows table
select shcode activityid, shdescr description into gettysburgstagingday..activities from shows where shcode in
(select distinct shcode from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
where eveventdate between @startdate and @enddate)

drop table temptickets2
select ticode,tipricetype,tifullprice,eveventdate, evcode, shcode, tilcode, timailinglist,titransactnum, 
(select top 1 ptdescr from recieptbase inner join paytype on rcbPayType = ptcode where rcbtransactnum = titransactnum) ptdescr ,
(select top 1 rcbshiftdate from recieptbase where rcbtransactnum = titransactnum) rcbshiftdate,
(select top 1 rcbcachinout from recieptbase where rcbtransactnum = titransactnum) rcbcachinout, 
(select sum(clcsum) from calculatedcommission where clcticketnum = ticode) fees,gogguidenumber guideid,tistatus,
0 minticode, 0 paymentid into temptickets2
from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
left outer join get_orderguides on gogordernumber = tiorder and gogticketid = ticode
where eveventdate between @startdate and @enddate

update t1
set minticode = minticode2
from 
temptickets2 t1 inner join (select min(ticode) minticode2, tipricetype,tifullprice,eveventdate, evcode, tilcode, timailinglist,tistatus,guideid,ptdescr,rcbshiftdate
from temptickets2 group by tipricetype,tifullprice,eveventdate, evcode, tilcode, timailinglist,tistatus,guideid,ptdescr,rcbshiftdate) t2 on
t1.tipricetype = t2.tipricetype and t1.tifullprice = t2.tifullprice and t1.eveventdate = t2.eveventdate and
t1.evcode = t2.evcode and t1.tilcode = t2.tilcode and t1.timailinglist = t2.timailinglist and t1.tistatus = t2.tistatus and isnull(t1.guideid,0) = isnull(t2.guideid,0)
and isnull(t1.ptdescr,'') = isnull(t2.ptdescr,'') and isnull(t1.rcbshiftdate,'2000-01-01') = isnull(t2.rcbshiftdate,'2000-01-01')

update t1
set paymentid = paymentid2
from 
temptickets2 t1 inner join (select min(rcbcode) paymentid2, timailinglist,ptdescr,temptickets2.rcbshiftdate, temptickets2.rcbcachinout
from temptickets2 inner join recieptbase on titransactnum = rcbtransactnum
left outer join recieptcredit on rcccode = rcbcode
group by timailinglist,ptdescr,temptickets2.rcbshiftdate, temptickets2.rcbcachinout) t2 on 
t1.timailinglist = t2.timailinglist and t1.ptdescr = t2.ptdescr and t1.rcbshiftdate = t2.rcbshiftdate and t1.rcbcachinout = t2.rcbcachinout

IF EXISTS (SELECT * FROM gettysburgstagingday.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'tickets')
drop table gettysburgstagingday..tickets

select minticode tickid, tipricetype pricetypeid, tiFullPrice price,evEventDate,shcode Activity,tilcode userid,tiMailingList contactid,count(*) qty, 
case when tistatus = 9 then 'Return' else 'Sale' end status, guideid+1000 guideid, fees,case when paymentid = 0 then null else paymentid end paymentid, max(titransactnum) last_transact_no 
into gettysburgstagingday..tickets
from temptickets2
group by minticode, tipricetype, tiFullPrice,evEventDate,shcode,tilcode,tiMailingList,tistatus,guideid, fees,paymentid 

IF EXISTS (SELECT * FROM gettysburgstagingday.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'payments')
drop table gettysburgstagingday..payments
select paymentid, 
ptdescr type, rcbshiftdate trandate, case when rcbcachinout = 1 then 'Refund' else 'Receipt' end mode,max(titransactnum) last_transact_no, 
max(rccCreditNum) lastCardNum, max(dbo.asc_xmlgetattribute('card_name',rccparamsdata)) lastCardName,
(select sum(rcbpayamount) from recieptbase r 
where rcbtransactnum in
(select t2.titransactnum from temptickets2 t2  
where t2.paymentid = t.paymentid)) amount into gettysburgstagingday..payments
from 
temptickets2 t
left outer join recieptcredit on rcccode = paymentid
where paymentid > 0
group by paymentid,timailinglist,ptdescr,rcbshiftdate, rcbcachinout


IF EXISTS (SELECT * FROM gettysburgstagingday.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'users')
drop table gettysburgstagingday..users


select user_name + '@gettysburgfoundation' guideid,first_name, last_name, cltemail email,pecode externalid into gettysburgstagingday..users
from SugarGettysburg..users u 
inner join pegettysburg2..ASC_SoapSyncCrossReference on u.id = sugarid and sugarmodule = 'Users'
inner join pegettysburg2..Guiders on gdrCode = pecode
INNER JOIN pegettysburg2..Clients ON gdrContactNoInRelTable = cltCode
where pecode in (select guideid from gettysburgstagingday..tickets)
/* This is the old versions
-- This query generates the data for the tickets table
select min(ticode) tickid, tipricetype pricetypeid, tiFullPrice price,evEventDate,shcode Activity,tilcode userid,tiMailingList contactid,count(*) qty,
case when tistatus = 9 then 'Return' else 'Sale' end status, gogguidenumber+ 1000 guideid,
(select min(rcbcode) from RecieptBase where rcbTransactNum = min(tiTransactNum)) paymentid 
 from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
left outer join get_orderguides on gogordernumber = tiorder and gogticketid = ticode
where eveventdate between @startdate and @enddate
group by tiFullPrice,evEventDate,shcode,tilcode,tiMailingList,tiStatus,tipricetype,gogguidenumber

-- This query generates the data for the payments table
select rcbcode paymentid,ptdescr type, rcbshiftdate trandate, rcbpayamount amount, 
case when rcbcachinout = 1 then 'Refund' else 'Receipt' end mode,
rcbtransactnum lastTransactNum, rccCreditNum lastCardNum, dbo.asc_xmlgetattribute('card_name',rccparamsdata) lastCardName
from
RecieptBase 
inner join paytype on rcbPayType = ptcode
left outer join recieptcredit on rcccode = rcbcode
where rcbcode in (select paymentid from gettysburgstagingday..tickets)
--group by cltcode,ptdescr,rcbshiftdate, rcbcachinout


select min(evcode) id,evshow activityid,'True' sundayavail, 'True' mondayavail, 'True' tuesdayavail, 'True' wednesdayavail, 'True' thursdayavail,
'True' fridayavail, 'True' saturdayavail,
min(eveventdate) startdate,max(eveventdate) enddate, 
convert(varchar(5),eveventdate,8) starttime,convert(varchar(5),dateadd(n,shlongminutes,eveventdate),8) finishtime
from events inner join shows on evshow = shcode
group by evshow,convert(varchar(5),eveventdate,8),convert(varchar(5),dateadd(n,shlongminutes,eveventdate),8)

*/
IF EXISTS (SELECT * FROM gettysburgstagingday.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'activitypriceschedule')
	drop table gettysburgstagingday..activitypriceschedule
select min(evcode) activityscheduleid,pctcode pricetypeid,min(pdcalculatedprice) price into gettysburgstagingday..activitypriceschedule
FROM PriceType 
INNER JOIN PriceDiscount ON PriceType.pctCode = PriceDiscount.pdPriceType 
INNER JOIN PriceList ON PriceDiscount.pdPriceList = PriceList.prlCode
inner join events on evPricelist = PriceList.prlCode
inner join shows on evshow = shcode
where pctcode in
(select distinct tipricetype from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
where eveventdate between @startdate and @enddate)
group by evshow,convert(varchar(5),eveventdate,8),convert(varchar(5),dateadd(n,shlongminutes,eveventdate),8),pctcode 


IF EXISTS (SELECT * FROM gettysburgstagingday.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'users')
drop table gettysburgstagingday..users


-- This query generates the data for the users table

select user_name + '@gettysburgfoundation' username,first_name, last_name, cltemail email,pecode + 1000 externalid into gettysburgstagingday..users
from SugarGettysburg..users u 
inner join pegettysburg2..ASC_SoapSyncCrossReference on u.id = sugarid and sugarmodule = 'Users'
inner join pegettysburg2..Guiders on gdrCode = pecode
INNER JOIN pegettysburg2..Clients ON gdrContactNoInRelTable = cltCode
where pecode in (select guideid -1000 guideid from GettysburgStagingDay..tickets)

insert into gettysburgstagingday..users (username,first_name, last_name, email,externalid)

select replace(tildescr,' ','_') + 'peuser@gettysburgfoundation','',replace(tildescr,' ','_'),'',tilcode externalid from till where tilcode in
(select distinct tilcode from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
where eveventdate between @startdate and @enddate)

IF EXISTS (SELECT * FROM gettysburgstagingday.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'activityschedule')
  drop table gettysburgstagingday..activityschedule

select min(evcode) id,evshow activityid,'True' sundayavail, 'True' mondayavail, 'True' tuesdayavail, 'True' wednesdayavail, 'True' thursdayavail,
'True' fridayavail, 'True' saturdayavail,
min(eveventdate) startdate,max(eveventdate) enddate, 
convert(varchar(5),eveventdate,8) starttime,convert(varchar(5),dateadd(n,shlongminutes,eveventdate),8) finishtime into gettysburgstagingday..activityschedule
from events inner join shows on evshow = shcode
where eveventdate between @startdate and @enddate
group by evshow,convert(varchar(5),eveventdate,8),convert(varchar(5),dateadd(n,shlongminutes,eveventdate),8)

IF EXISTS (SELECT * FROM gettysburgstagingday.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'activitypriceschedule')
drop table gettysburgstagingday..activitypriceschedule
select min(evcode) activityscheduleid,pctcode pricetypeid,min(pdcalculatedprice) price into gettysburgstagingday..activitypriceschedule
FROM PriceType 
INNER JOIN PriceDiscount ON PriceType.pctCode = PriceDiscount.pdPriceType 
INNER JOIN PriceList ON PriceDiscount.pdPriceList = PriceList.prlCode
inner join events on evPricelist = PriceList.prlCode and eveventdate between @startdate and @enddate
inner join shows on evshow = shcode
where pctcode in
(select distinct tipricetype from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
where eveventdate between @startdate and @enddate)
group by evshow,convert(varchar(5),eveventdate,8),convert(varchar(5),dateadd(n,shlongminutes,eveventdate),8),pctcode 


IF EXISTS (SELECT * FROM gettysburgstagingday.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'lookuptimes')
  drop table gettysburgstagingday..lookuptimes
select starttime timevalue,datepart(hh,starttime) *60 + datepart(mi,starttime) min into gettysburgstagingday..lookuptimes
from gettysburgstagingday..activityschedule 
union 
select finishtime, datepart(hh,finishtime) *60 + datepart(mi,finishtime) from gettysburgstagingday..activityschedule
