create procedure decofc_createtempticketstosync @startdate datetime, @enddate datetime  as
begin 
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
where eveventdate between @startdate and @startdate

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
end