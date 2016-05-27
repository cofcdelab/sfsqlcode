-- This query generates the data for the contacts table
IF EXISTS (SELECT * FROM gettysburgstaging.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'contacts')
  drop table gettysburgstaging..contacts
select cltcode, cltfirstname, cltSurName,cltEmail into gettysburgstaging..contacts
from clients where cltcode in 
(select distinct timailinglist from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
where eveventdate between '2014-10-01' and '2015-01-31 23:59')




drop table gettysburgstaging..pricetypes 
-- This query generates the data for the pricetype table
select pctcode pricetypeid, pctdescr description into gettysburgstaging..pricetypes from PriceType where pctcode in
(select distinct tipricetype from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
where eveventdate between '2014-10-01' and '2015-01-31 23:59')


drop table gettysburgstaging..activities 
-- This query generates the data for the shows table
select shcode activityid, shdescr description into gettysburgstaging..activities from shows where shcode in
(select distinct shcode from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
where eveventdate between '2014-10-01' and '2015-01-31 23:59')

drop table temptickets
select ticode,tipricetype,tifullprice,eveventdate, evcode, shcode, tilcode, timailinglist,titransactnum, 
(select top 1 ptdescr from recieptbase inner join paytype on rcbPayType = ptcode where rcbtransactnum = titransactnum) ptdescr ,
(select top 1 rcbshiftdate from recieptbase where rcbtransactnum = titransactnum) rcbshiftdate,
(select top 1 rcbcachinout from recieptbase where rcbtransactnum = titransactnum) rcbcachinout, 
(select sum(clcsum) from calculatedcommission where clcticketnum = ticode) fees,gogguidenumber guideid,tistatus,
0 minticode, 0 paymentid into temptickets
from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
left outer join get_orderguides on gogordernumber = tiorder and gogticketid = ticode
where eveventdate between '2014-10-01' and '2015-01-31 23:59'

update t1
set minticode = minticode2
from 
temptickets t1 inner join (select min(ticode) minticode2, tipricetype,tifullprice,eveventdate, evcode, tilcode, timailinglist,tistatus,guideid,ptdescr,rcbshiftdate
from temptickets group by tipricetype,tifullprice,eveventdate, evcode, tilcode, timailinglist,tistatus,guideid,ptdescr,rcbshiftdate) t2 on
t1.tipricetype = t2.tipricetype and t1.tifullprice = t2.tifullprice and t1.eveventdate = t2.eveventdate and
t1.evcode = t2.evcode and t1.tilcode = t2.tilcode and t1.timailinglist = t2.timailinglist and t1.tistatus = t2.tistatus and isnull(t1.guideid,0) = isnull(t2.guideid,0)
and isnull(t1.ptdescr,'') = isnull(t2.ptdescr,'') and isnull(t1.rcbshiftdate,'2000-01-01') = isnull(t2.rcbshiftdate,'2000-01-01')

update t1
set paymentid = paymentid2
from 
temptickets t1 inner join (select min(rcbcode) paymentid2, timailinglist,ptdescr,temptickets.rcbshiftdate, temptickets.rcbcachinout
from temptickets inner join recieptbase on titransactnum = rcbtransactnum
left outer join recieptcredit on rcccode = rcbcode
group by timailinglist,ptdescr,temptickets.rcbshiftdate, temptickets.rcbcachinout) t2 on 
t1.timailinglist = t2.timailinglist and t1.ptdescr = t2.ptdescr and t1.rcbshiftdate = t2.rcbshiftdate and t1.rcbcachinout = t2.rcbcachinout

drop table GettysburgStaging..tickets

select minticode tickid, min(evcode) activityscheduleid, tipricetype pricetypeid, tiFullPrice price,evEventDate,shcode Activity,tilcode userid,tiMailingList contactid,count(*) qty, 
case when tistatus = 9 then 'Return' else 'Sale' end status, guideid+1000 guideid, fees,case when paymentid = 0 then null else paymentid end paymentid, max(titransactnum) last_transact_no 
into GettysburgStaging..tickets
from temptickets
group by minticode, tipricetype, tiFullPrice,evEventDate,shcode,tilcode,tiMailingList,tistatus,guideid, fees,paymentid 

drop table gettysburgstaging..payments
select paymentid, 
ptdescr type, rcbshiftdate trandate, case when rcbcachinout = 1 then 'Refund' else 'Receipt' end mode,max(titransactnum) last_transact_no, 
max(rccCreditNum) lastCardNum, max(dbo.asc_xmlgetattribute('card_name',rccparamsdata)) lastCardName,
(select sum(rcbpayamount) from recieptbase r 
where rcbtransactnum in
(select t2.titransactnum from temptickets t2  
where t2.paymentid = t.paymentid)) amount into gettysburgstaging..payments
from 
temptickets t
left outer join recieptcredit on rcccode = paymentid
where paymentid > 0
group by paymentid,timailinglist,ptdescr,rcbshiftdate, rcbcachinout


IF EXISTS (SELECT * FROM gettysburgstaging.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'activitypriceschedule')
drop table gettysburgstaging..activitypriceschedule
select min(evcode) activityscheduleid,pctcode pricetypeid,min(pdcalculatedprice) price into gettysburgstaging..activitypriceschedule
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
where eveventdate between '2014-10-01' and '2015-01-31 23:59')
group by evshow,convert(varchar(5),eveventdate,8),convert(varchar(5),dateadd(n,shlongminutes,eveventdate),8),pctcode 


IF EXISTS (SELECT * FROM gettysburgstaging.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'users')
drop table gettysburgstaging..users
go

-- This query generates the data for the users table

select user_name + '@gettysburgfoundation' username,first_name, last_name, cltemail email,pecode + 1000 externalid into gettysburgstaging..users
from SugarGettysburg..users u 
inner join pegettysburg2..ASC_SoapSyncCrossReference on u.id = sugarid and sugarmodule = 'Users'
inner join pegettysburg2..Guiders on gdrCode = pecode
INNER JOIN pegettysburg2..Clients ON gdrContactNoInRelTable = cltCode
where pecode in (select guideid -1000 guideid from GettysburgStaging..tickets)

insert into gettysburgstaging..users (username,first_name, last_name, email,externalid)

select replace(tildescr,' ','_') + 'peuser@gettysburgfoundation','',replace(tildescr,' ','_'),'',tilcode externalid from till where tilcode in
(select distinct tilcode from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
where eveventdate between '2014-10-01' and '2015-01-31 23:59')

drop table gettysburgstaging..activityschedule
select min(evcode) id,evshow activityid,'True' sundayavail, 'True' mondayavail, 'True' tuesdayavail, 'True' wednesdayavail, 'True' thursdayavail,
'True' fridayavail, 'True' saturdayavail,
min(eveventdate) startdate,max(eveventdate) enddate, 
convert(varchar(5),eveventdate,8) starttime,convert(varchar(5),dateadd(n,shlongminutes,eveventdate),8) finishtime into gettysburgstaging..activityschedule
from events inner join shows on evshow = shcode
where eveventdate between '2014-10-01' and '2015-01-31 23:59'
group by evshow,convert(varchar(5),eveventdate,8),convert(varchar(5),dateadd(n,shlongminutes,eveventdate),8)

IF EXISTS (SELECT * FROM gettysburgstaging.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'lookuptimes')
  drop table gettysburgstaging..lookuptimes
select starttime timevalue,datepart(hh,starttime) *60 + datepart(mi,starttime) min into gettysburgstaging..lookuptimes
from gettysburgstaging..activityschedule 
union 
select finishtime, datepart(hh,finishtime) *60 + datepart(mi,finishtime) from gettysburgstaging..activityschedule
