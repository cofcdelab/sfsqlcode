-- This query generates the data for the contacts table
drop table gettysburgstaging..contacts

select cltcode, cltfirstname, cltSurName,cltEmail into gettysburgstaging..contacts
from clients where cltcode in 
(select distinct timailinglist from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
where eveventdate between '2014-10-01' and '2015-09-30 23:59')

/*
-- This query generates the data for the users table
select tilcode userid, tildescr username from till where tilcode in
(select distinct tilcode from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
where eveventdate between '2014-10-01' and '2015-09-30 23:59')

-- This query generates the data for the guides table
select gdrcode+1000 guideid,gdrfirstname + ' ' + gdrlastname guidename from guiders
*/

drop table gettysburgstaging..pricetypes 
-- This query generates the data for the pricetype table
select pctcode pricetypeid, pctdescr description into gettysburgstaging..pricetypes from PriceType where pctcode in
(select distinct tipricetype from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
where eveventdate between '2014-10-01' and '2015-09-30 23:59')


drop table gettysburgstaging..activities 
-- This query generates the data for the shows table
select shcode activityid, shdescr description into gettysburgstaging..activities from shows where shcode in
(select distinct shcode from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
where eveventdate between '2014-10-01' and '2015-09-30 23:59')

drop table temptickets
select ticode,tipricetype,tifullprice,eveventdate, shcode, tilcode, timailinglist,titransactnum, 
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
where eveventdate between '2014-10-01' and '2015-09-30 23:59'

update t1
set minticode = minticode2
from 
temptickets t1 inner join (select min(ticode) minticode2, tipricetype,tifullprice,eveventdate, shcode, tilcode, timailinglist
from temptickets group by tipricetype,tifullprice,eveventdate, shcode, tilcode, timailinglist) t2 on
t1.tipricetype = t2.tipricetype and t1.tifullprice = t2.tifullprice and t1.eveventdate = t2.eveventdate and
t1.shcode = t2.shcode and t1.tilcode = t2.tilcode and t1.timailinglist = t2.timailinglist

update t1
set paymentid = paymentid2
from 
temptickets t1 inner join (select min(rcbcode) paymentid2, timailinglist,ptdescr,temptickets.rcbshiftdate, temptickets.rcbcachinout
from temptickets inner join recieptbase on titransactnum = rcbtransactnum
left outer join recieptcredit on rcccode = rcbcode
group by timailinglist,ptdescr,temptickets.rcbshiftdate, temptickets.rcbcachinout) t2 on 
t1.timailinglist = t2.timailinglist and t1.ptdescr = t2.ptdescr and t1.rcbshiftdate = t2.rcbshiftdate and t1.rcbcachinout = t2.rcbcachinout

drop table GettysburgStaging..tickets

select minticode tickid, tipricetype pricetypeid, tiFullPrice price,evEventDate,shcode Activity,tilcode userid,tiMailingList contactid,count(*) qty, 
case when tistatus = 9 then 'Return' else 'Sale' end status, user_name + '@gettysburgfoundation' guideid, fees,paymentid, max(titransactnum) last_transact_no 
into GettysburgStaging..tickets
from temptickets
left outer join ASC_SoapSyncCrossReference on pecode = guideid and sugarmodule = 'Users'
left outer join SugarGettysburg..users u on u.id = sugarid
group by minticode, tipricetype, tiFullPrice,evEventDate,shcode,tilcode,tiMailingList,tistatus,user_name, fees,paymentid 

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
group by paymentid,timailinglist,ptdescr,rcbshiftdate, rcbcachinout


select user_name + '@gettysburgfoundation' guideid,first_name, last_name, cltemail email into gettysburgstaging..users
from SugarGettysburg..users u 
inner join pegettysburg..ASC_SoapSyncCrossReference on u.id = sugarid and sugarmodule = 'Users'
inner join pegettysburg..Guiders on gdrCode = pecode
INNER JOIN pegettysburg..Clients ON gdrContactNoInRelTable = cltCode
where user_name + '@gettysburgfoundation' in (select guideid from GettysburgStaging..tickets)
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
where eveventdate between '2014-10-01' and '2015-09-30 23:59'
group by tiFullPrice,evEventDate,shcode,tilcode,tiMailingList,tiStatus,tipricetype,gogguidenumber

-- This query generates the data for the payments table
select rcbcode paymentid,ptdescr type, rcbshiftdate trandate, rcbpayamount amount, 
case when rcbcachinout = 1 then 'Refund' else 'Receipt' end mode,
rcbtransactnum lastTransactNum, rccCreditNum lastCardNum, dbo.asc_xmlgetattribute('card_name',rccparamsdata) lastCardName
from
RecieptBase 
inner join paytype on rcbPayType = ptcode
left outer join recieptcredit on rcccode = rcbcode
where rcbcode in (select paymentid from GettysburgStaging..tickets)
--group by cltcode,ptdescr,rcbshiftdate, rcbcachinout


select min(evcode) id,evshow activityid,'True' sundayavail, 'True' mondayavail, 'True' tuesdayavail, 'True' wednesdayavail, 'True' thursdayavail,
'True' fridayavail, 'True' saturdayavail,
min(eveventdate) startdate,max(eveventdate) enddate, 
convert(varchar(5),eveventdate,8) starttime,convert(varchar(5),dateadd(n,shlongminutes,eveventdate),8) finishtime
from events inner join shows on evshow = shcode
group by evshow,convert(varchar(5),eveventdate,8),convert(varchar(5),dateadd(n,shlongminutes,eveventdate),8)


select min(evcode) activityscheduleid,pctcode pricetypeid,min(pdcalculatedprice) price
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
where eveventdate between '2014-10-01' and '2015-09-30 23:59')
group by evshow,convert(varchar(5),eveventdate,8),convert(varchar(5),dateadd(n,shlongminutes,eveventdate),8),pctcode 
*/
