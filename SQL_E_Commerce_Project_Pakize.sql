

---- examining data

---- cust_dimen table:

select	*
from	cust_dimen -- total 1832 rows


---rearranging Cust_id column

update	cust_dimen
set			Cust_Id = REPLACE(Cust_Id, 'Cust_', '')
where		Cust_Id like 'Cust_%'


EXEC sp_rename 'cust_dimen.Cust_ID', 'Cust_id';

select	Cust_ID
from	cust_dimen

alter table		cust_dimen 
add PRIMARY KEY (Cust_ID)

alter table		cust_dimen
alter column	Cust_id INT not null


---- market_fact table:

select distinct *
from market_fact -- total 8399 rows



select distinct	Ord_id
from					market_fact -- total 5506 rows
group by				Ord_id
order by				Ord_id


---rearranging some columns
update	market_fact
set			Prod_id=Replace(Prod_id, 'Prod_', ''), 
				Cust_Id = REPLACE(Cust_id, 'Cust_', ''),
				Ord_id=REPLACE(Ord_id, 'Ord_', ''),
				Ship_id=Replace(Ship_id, 'SHP_', '')
where		Prod_id like 'Prod_%'
and			Cust_id like 'Cust_%'
and			Ord_id like 'Ord_%'
and			Ship_id like 'SHP_%'


alter table		market_fact
alter column Ord_id INT not null

alter table		market_fact
alter column Prod_id INT not null

alter table		market_fact
alter column	Ship_id INT not null

alter table		market_fact
alter column	Cust_id INT not null


---- orders_dimen table:


select distinct * 
from orders_dimen -- total 5506 rows


---rearranging Ord_id column:
update	orders_dimen
set			Ord_id=REPLACE(Ord_id, 'Ord_', '')
where		Ord_id like 'Ord_%'

alter table orders_dimen
ALTER COLUMN Ord_id INT not null

alter table orders_dimen
add PRIMARY KEY (Ord_id) 


---- prod_dimen table:

select *
from prod_dimen -- total 17 rows


---rearranging Prod_id column:
update	prod_dimen
set			Prod_id=Replace(Prod_id, 'Prod_', '')
where		Prod_id like 'Prod_%'

alter table		prod_dimen
alter column Prod_id INT not null

alter table		prod_dimen
add primary key (Prod_id)

---- shipping_dimen table:

select *
from shipping_dimen
order by Ship_id -- total 7701 rows


---rearranging Ship_id column:
update	shipping_dimen
set			Ship_id=Replace(Ship_id, 'SHP_', '')
where		Ship_id like 'SHP_%'

alter table		shipping_dimen
alter column Ship_id INT not null

alter table		shipping_dimen
add primary key (Ship_id)

EXEC sp_rename 'shipping_dimen.Order_ID', 'Ord_id';

---------------------------------------------------------

/*
1. Using the columns of “market_fact”, “cust_dimen”, “orders_dimen”, “prod_dimen”, “shipping_dimen”, 
create a new table, named as “combined_table”. 
*/

SELECT *
INTO
combined_table
FROM
(
select e.Cust_id, e.Customer_Name, e.Province, e.Region, e.Customer_Segment, 
			b.Ord_id, b.Order_Date, b.Order_Priority,
			a.Sales, a.Discount, a.Order_Quantity, a.Product_Base_Margin,
			c.Prod_id, c.Product_Category, c.Product_Sub_Category,
			d.Ship_id, d.Ship_Date, d.Ship_Mode
from market_fact A, orders_dimen B, prod_dimen C, shipping_dimen D, cust_dimen E
where a.Ord_id=b.Ord_id
and a.Prod_id=c.Prod_id
and a.Ship_id=d.Ship_id
and a.Cust_id=e.Cust_id
) A

select * from combined_table
order by Ord_id


alter table		combined_table
alter column	Cust_id INT not null


-------
/*
2. Find the top 3 customers who have the maximum count of orders.
*/


select			TOP 3 Cust_id, Customer_Name, COUNT (Ord_id) cnt_orders
from			combined_table
group by		Cust_id, Customer_Name
order by		COUNT (Ord_id) DESC 

-------
/*
3. Create a new column at combined_table as DaysTakenForShipping that 
contains the date difference of Order_Date and Ship_Date.
*/

select *,
			datediff(day, Order_Date, Ship_Date) DaysTakenForShipping
from	combined_table


ALTER TABLE combined_table ADD DaysTakenForShipping INT null 


UPDATE combined_table SET DaysTakenForShipping = DateDiff(day, Order_Date, Ship_Date)

select *
from combined_table


------------
/*
4. Find the customer whose order took the maximum time to get delivered.
*/

select		top 1 Cust_id, Customer_Name, Order_Date, Ship_Date, DaysTakenForShipping
from		combined_table
order by DaysTakenForShipping Desc

--------------
/*
5. Count the total number of unique customers in January and how many of them 
came back every month over the entire year in 2011
*/

select		DISTINCT Cust_id
from		combined_table
where		Year(Order_Date) = 2011
and			MONTH(Order_Date) = 01


---total number of unique customers in January 2011:
select		Year(Order_Date) ord_year,  MONTH(Order_Date) ord_month,  Count (DISTINCT Cust_id) AS cnt_customer
from		combined_table
where		Year(Order_Date) = 2011
and			MONTH(Order_Date) = 01
group by Year(Order_Date),  MONTH(Order_Date)

--SOLUTION:

select		Year(Order_Date) ord_year,  MONTH(Order_Date) ord_month, Count (DISTINCT Cust_id) AS cnt_customer 
from		combined_table
where		Year(Order_Date) = 2011
and			Cust_id in
					(
					select DISTINCT Cust_id
					from combined_table
					where Year(Order_Date) = 2011
					and MONTH(Order_Date) = 01
					)
group by Year(Order_Date),  MONTH(Order_Date)


---- controlling the query for February:

select		Year(Order_Date) ord_year,  MONTH(Order_Date) ord_month, Count ( DISTINCT Cust_id) AS cnt_customer_february
from		combined_table
where		Year(Order_Date) = 2011
and			MONTH(Order_Date) = 02
and			Cust_id in
				(
				select DISTINCT Cust_id
				from combined_table
				where Year(Order_Date) = 2011
				and MONTH(Order_Date) = 01
				)
group by Year(Order_Date),  MONTH(Order_Date)


---------------
/*
6. Write a query to return for each user the time elapsed between the first 
purchasing and the third purchasing, in ascending order by Customer ID.   
*/

---- first create a view to get a dense_rank:

Create view v_dense_number As
SELECT	Cust_id, Ord_id, Order_Date,
				DENSE_RANK() OVER(Partition by Cust_id ORDER BY Order_Date) AS dense_number
FROM		combined_table



select *
from v_dense_number
order by Cust_id, Order_Date


--check if it is working:

select		Cust_id, Order_Date AS first_order_date
from		v_dense_number
where		dense_number =1 
order by	Cust_id, Order_Date

select		Cust_id, Order_Date AS third_order_date, dense_number
from		v_dense_number
where		dense_number =3
order by	Cust_id, Order_Date

--
--SOLUTION:

with first_ord as
(
		select Cust_id, Order_Date AS first_order_date
		from v_dense_number
		where dense_number =1 

), third_ord as
(
		select Cust_id, Order_Date AS third_order_date, dense_number
		from v_dense_number 
		where dense_number =3

)
select		DISTINCT a.Cust_id, a.first_order_date, b.dense_number, b.third_order_date, 
				Datediff(day, a.first_order_date,b.third_order_date) day_elapsed
from		first_ord a, third_ord b
where		a.Cust_id=b. Cust_id
order by	a.Cust_id




/*
7. Write a query that returns customers who purchased both product 11 and 
product 14, as well as the ratio of these products to the total number of 
products purchased by the customer.
*/


select		Cust_id, Ord_id, Prod_id
from		combined_table
where		Cust_id =1538
order by	Cust_id  ---numbers are different from the result table

--checking
select		Cust_id, count(Prod_id) AS Total_Prod
from		combined_table
group by Cust_id

select		Cust_id, Prod_id,  count(Prod_id)
from		combined_table
where		Cust_id = 583   ----> 1 TANE P11 ALMIS VE 1 TANE DE P14 ALMIS
group by Cust_id, Prod_id


--solution (the numbers are different from the result table but the result is correct according to my own table and data)
--I don't know, maybe I used the wrong table.

with total as
(
		select		Cust_id, count(Prod_id) AS Total_Prod
		from		combined_table
		group by Cust_id
), cnt_prod as 
(
		select		Cust_id, 
				sum(case when Prod_id = 11 then 1 else 0 end ) as P11,
				sum(case when Prod_id = 14 then 1 else 0 end) as P14
		from		combined_table
		group by Cust_id
		having
				sum(case when Prod_id = 11 then 1 else 0 end ) > 0
				and
				sum(case when Prod_id = 14 then 1 else 0 end) > 0
)
select		b.*, a.Total_Prod, Round((CAST (b.P11 as float)/a.Total_Prod), 2) as ratio_P11, 
				Round((CAST(b.P14 as float)/a.Total_Prod),2) as ratio_P14
from		total a, cnt_prod b
where		a.Cust_id=b.Cust_id




----- Customer Retention Analysis Phase:

/*
1. Create a “view” that keeps visit logs of customers on a monthly basis. (For 
each log, three field is kept: Cust_id, Year, Month)
*/

create view v_logs_of_customers AS
select	Cust_id, YEAR(Order_Date) AS YEAR, Month(Order_Date) AS MONTH
from	combined_table

select *
from v_logs_of_customers


-----
/*
2. Create a “view” that keeps the number of monthly visits by users. (Show 
separately all months from the beginning business)
*/

create view v_num_of_visits AS
select		Cust_id, YEAR(Order_Date) AS YEAR, Month(Order_Date) AS MONTH, Count (Order_Date) NUM_OF_LOG
from		combined_table
group by Cust_id, YEAR(Order_Date), Month(Order_Date)

select *
from  v_num_of_visits
order by Cust_id

------
/*
3. For each visit of customers, create the next month of the visit as a separate 
column.
*/

select *,
			Dense_rank() OVER (ORDER by [YEAR], [MONTH]) current_month
from	v_num_of_visits


--
create view v_next_visit as
with cm as
(
		select *,
				Dense_rank() OVER (ORDER by [YEAR], [MONTH]) current_month
		from  v_num_of_visits
)
select *,
			LEAD(current_month) OVER (partition by Cust_id order by current_month) as month_of_next_visit
from cm


select *
from v_next_visit
order by 1,2


/*
4. Calculate the monthly time gap between two consecutive visits by each 
customer.
*/

create view v_time_gap as
select *, (month_of_next_visit - current_month) as time_gap
from v_next_visit



select *
from v_time_gap
order by 1,2


/*
5. Categorise customers using average time gaps. Choose the most fitted
labeling model for you.
For example: 
- Labeled as churn if the customer hasn't made another purchase in the 
months since they made their first purchase.
- Labeled as regular if the customer has made a purchase every month.
Etc.
*/


create view v_cust_labels as
with atg as
(
		select *, avg(time_gap) Over (partition by Cust_id) avg_time_gap
		from v_time_gap
)
select *,
		case 
		when	avg_time_gap = 1 then 'Regular'
		when	avg_time_gap > 1 then 'Irregular'
		when	avg_time_gap is null then 'Churn'
		else		'Unknown'
		end as Cust_Labels
from atg


select *
from v_cust_labels
order by 1,2



---------Month-Wise Retention Rate


/*
1. Find the number of customers retained month-wise. 
*/


select		distinct Cust_id, [YEAR], [MONTH], current_month, month_of_next_visit, time_gap,
				count(Cust_id) over (Partition by month_of_next_visit) as retention_month_wise  --> number of customer retained in the current month
from		v_time_gap
where		time_gap=1
order by 1,2



/*
2. Calculate the month-wise retention rate.
*/

----calculate total number of customers in the current month


select *
from v_time_gap


---checking for month 2 and 3:
select		count(Cust_id)
from		v_time_gap
where		[YEAR] =2009
and			[MONTH]=2


select		count(Cust_id)
from		v_time_gap
where		[YEAR] =2009
and			[MONTH]=3

--
--total number of customers in the current month

select		distinct current_month,
				count(Cust_id) Over (Partition by current_month) total_cust_curr_mnth
from		v_time_gap
order by current_month


--- month-wise retention rate = 1.0*num. of customers retained in the currenth month/total number of customers in the current month

--Solution:
with ret_mnth as
(
		select	distinct Cust_id, [YEAR], [MONTH], current_month, month_of_next_visit, time_gap,
					count(Cust_id) over (Partition by month_of_next_visit) as retention_month_wise  
		from	v_time_gap
		where time_gap=1

), total_cust as
(
		select	distinct current_month,
					count(Cust_id) Over (Partition by current_month) total_cust_curr_mnth
		from	v_time_gap
)
select	distinct a.[YEAR], a.[MONTH],
			Round((Cast(a.retention_month_wise as float)/b.total_cust_curr_mnth), 2) as retention_rate
from	ret_mnth a, total_cust b
where a.current_month=b.current_month













































































