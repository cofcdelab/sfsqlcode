declare @startdate datetime 
SET @startdate = '2014-10-01'
declare @enddate datetime 
SET @enddate = '2014-10-01 23:59'
declare @emailsuffix varchar(255)
SET @emailsuffix = '@gettysburgfoundation.com.cofc'
--SET @enddate = '2016-04-01 23:59'

IF EXISTS (SELECT * FROM gettysburgstagingday.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'accounts')
	drop table gettysburgstagingday..accounts

select min(orcrecordid) recid , cltEmail,orcfullname,adraddress1, adraddress2, adrcitydesc, adrstatedesc, adrzipcode, adrcountrydesc,
(select top 1 cpnphonenumber from clientphonenumbers where cpnclientcode = cltcode) phone into gettysburgstagingday..accounts
from clients 
inner join tickets on timailinglist = cltcode 
inner join events on tievent = evcode
inner join OrderContacts on orcordernumber = tiorder 
left outer join clientaddresses on claclientcode = cltcode and claisformailing = 1
left outer join addresses on claaddresscode = adrcode
where eveventdate between @startdate and @enddate
and len(ltrim(cltfirstname)) <> 0
group by cltcode,cltEmail,orcfullname,adraddress1, adraddress2, adrcitydesc, adrstatedesc, adrzipcode, adrcountrydesc
UNION 
select cltcode, cltEmail,cltSurName,adraddress1, adraddress2, adrcitydesc, adrstatedesc, adrzipcode, adrcountrydesc,
(select top 1 cpnphonenumber from clientphonenumbers where cpnclientcode = cltcode) phone
from clients 
inner join tickets on timailinglist = cltcode 
inner join events on tievent = evcode
inner join OrderContacts on orcordernumber = tiorder
left outer join clientaddresses on claclientcode = cltcode and claisformailing = 1
left outer join addresses on claaddresscode = adrcode
where eveventdate between @startdate and @enddate
and len(ltrim(cltfirstname)) = 0
group by cltcode, cltSurName,cltEmail,adraddress1, adraddress2, adrcitydesc, adrstatedesc, adrzipcode, adrcountrydesc


IF EXISTS (SELECT * FROM gettysburgstagingday.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'contacts')
	drop table gettysburgstagingday..contacts

select cltcode, cltfirstname, cltSurName,cltEmail,adraddress1, adraddress2, adrcitydesc, adrstatedesc, adrzipcode, adrcountrydesc,
(select top 1 cpnphonenumber from clientphonenumbers where cpnclientcode = cltcode) phone into gettysburgstagingday..contacts
from clients 
left outer join clientaddresses on claclientcode = cltcode and claisformailing = 1
left outer join addresses on claaddresscode = adrcode
where cltcode in 
(select distinct timailinglist from tickets 
inner join events on tievent = evcode
inner join shows on evshow = shcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join till on sftill = tilCode
left outer join clients on timailinglist = cltcode
where eveventdate between @startdate and @enddate
and len(ltrim(cltfirstname)) <> 0
)


IF EXISTS (SELECT * FROM gettysburgstagingday.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'orders')
	drop table gettysburgstagingday..orders

select tiorder ordernumber, recid accountid, cltcode billingcontactid, convert(varchar(10),min(eveventdate),101) visitdate,
convert(varchar(10),min(sfactiondate),101) orderstartdate into gettysburgstagingday..orders
from clients 
inner join tickets on timailinglist = cltcode 
inner join events on tievent = evcode
inner join shifts on tishift = sfcode and sfActionType = 0
inner join OrderContacts on orcordernumber = tiorder 
inner join gettysburgstagingday..accounts on orcrecordid =  recid
where eveventdate between @startdate  and @enddate
and len(ltrim(cltfirstname)) <> 0
group by tiorder, recid,cltcode
UNION 
select tiorder,cltcode,0, convert(varchar(10),min(eveventdate),101),
convert(varchar(10),min(sfactiondate),101)
from clients 
inner join tickets on timailinglist = cltcode 
inner join shifts on tishift = sfcode and sfActionType = 0
inner join events on tievent = evcode
where eveventdate between @startdate and @enddate
and len(ltrim(cltfirstname)) = 0
group by tiorder, cltcode
