-- inspecting data
select * from [dbo].[sales_data_sample]
--- checking unique values
select distinct status from [dbo].[sales_data_sample] --Nice one to plot
select distinct year_id from [dbo].[sales_data_sample]
select distinct PRODUCTLINE from [dbo].[sales_data_sample] ---Nice to plot
select distinct COUNTRY from [dbo].[sales_data_sample] ---Nice to plot
select distinct DEALSIZE from [dbo].[sales_data_sample] ---Nice to plot
select distinct TERRITORY from [dbo].[sales_data_sample] ---Nice to plot


select distinct MONTH_ID from [dbo].[sales_data_sample] -- how many months operated in 2005
where year_id = 2005
select distinct MONTH_ID from [dbo].[sales_data_sample] -- how many months operated in 2003
where year_id = 2003
select distinct MONTH_ID from [dbo].[sales_data_sample] -- how many months operated in 2004
where year_id = 2004




--Analysis
--let's start by grouping sales by productline //which product sells the most
select PRODUCTLINE, sum(sales) Revenue -- anytime for aggregate fn we have to do groupby
from [dbo].[sales_data_sample]
group by PRODUCTLINE
order by 2 desc  -- position 2 and desc for highest amount on top and least at bottom

select YEAR_ID, sum(sales) Revenue --- by year
from [dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc

select  DEALSIZE,  sum(sales) Revenue -- by deal size
from [dbo].[sales_data_sample]
group by  DEALSIZE
order by 2 desc

----What was the best month for sales in a specific year? How much was earned that month? 
select  MONTH_ID, sum(sales) Revenue, count(ORDERNUMBER) Frequency  -- for 2003
from [dbo].[sales_data_sample]
where YEAR_ID = 2003 
group by  MONTH_ID
order by 2 desc

select  MONTH_ID, sum(sales) Revenue, count(ORDERNUMBER) Frequency --for 2004
from [dbo].[sales_data_sample]
where YEAR_ID = 2004 
group by  MONTH_ID
order by 2 desc

select  MONTH_ID, sum(sales) Revenue, count(ORDERNUMBER) Frequency --for 2005 only 5 month
from [dbo].[sales_data_sample]
where YEAR_ID = 2005 
group by  MONTH_ID
order by 2 desc


--November seems to be the month, what product do they sell in November, Classic I believe
select  MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER) --for 2003
from [dbo].[sales_data_sample]
where YEAR_ID = 2003 and MONTH_ID = 11 
group by  MONTH_ID, PRODUCTLINE
order by 3 desc

select  MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER) -- for 2004
from [dbo].[sales_data_sample]
where YEAR_ID = 2004 and MONTH_ID = 11 
group by  MONTH_ID, PRODUCTLINE
order by 3 desc

select  MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER) -- for 2005
from [dbo].[sales_data_sample]
where YEAR_ID = 2005 and MONTH_ID = 5   
group by  MONTH_ID, PRODUCTLINE
order by 3 desc


----Who is our best customer (this could be best answered with RFM)
--in this case:-
--recency-last order date
--frequency-count of total order
--monetary-total spend

DROP TABLE IF EXISTS #rfm
;with rfm as 
(
	select 
		CUSTOMERNAME, 
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from [dbo].[sales_data_sample]) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) Recency
	from [dbo].[sales_data_sample] 
	group by CUSTOMERNAME
),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r

)
select 
	c.*,rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm


--What products are most often sold together? 
--select * from [dbo].[sales_data_sample] where ORDERNUMBER =  10411
select distinct OrderNumber, stuff(
	(select ','+ PRODUCTCODE
	from [dbo].[sales_data_sample] p
	where ORDERNUMBER in 
		(
			select ORDERNUMBER
			from(
				select ORDERNUMBER, count(*) rn
				FROM [dbo].[sales_data_sample]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn=3  -- only 2 items order 19 times 3 then 13
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))
		 ,1,1,'') productcodes
from [dbo].[sales_data_sample] s
order by 2 desc

