use namastesql;
/*
download credit card transactions dataset from below link :
https://www.kaggle.com/datasets/thedevastator/analyzing-credit-card-spending-habits-in-india
import the dataset in sql server with table name : credit_card_transcations
change the column names to lower case before importing data to sql server.Also replace space within column names with underscore.
(alternatively you can use the dataset present in zip file)
while importing make sure to change the data types of columns. by defualt it shows everything as varchar.
*/

select * from credit_card_transcations
group by city

-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

select top 5 city, max(amount) as highest_amount_spent, sum(amount) *100.0 / (SELECT SUM(CAST(amount AS BIGINT))
FROM credit_card_transcations) as percent_spent
from credit_card_transcations
group by city
order by percent_spent desc ;

-- 2- write a query to print highest spend month and amount spent in that month for each card type


with cte as (
SELECT
    card_type,
    YEAR(transaction_date) AS yr,
    MONTH(transaction_date) AS mth,
    SUM(amount) AS total_spent_month
FROM
    credit_card_transcations
GROUP BY card_type, YEAR(transaction_date), MONTH(transaction_date)
),
rn_cte as (
select *,
	ROW_NUMBER() over(partition by card_type order by total_spent_month desc) as rn
from cte )
select card_type, yr, mth, total_spent_month
from rn_cte
where rn = 1;



-- 3- write a query to print the transaction details(all columns from the table) for each card type 
-- when it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
with cte as (
select *, sum(amount) over(partition by card_type order by transaction_date,transaction_id) as total_spend
from credit_card_transcations ),
cte2 as (
select *, row_number() over(partition by card_type order by total_spend asc) as rn
from cte 
where total_spend >= 1000000
)
select * from cte2
where rn = 1 
;



-- 4- write a query to find city which had lowest percentage spend for gold card type
with cte as (
select city, card_type, sum(amount) as total_spent, sum(case when card_type = 'Gold' then amount end) as Gold_amount
from credit_card_transcations
group by city, card_type )
select top 1 city, sum(Gold_amount) * 1.0 / sum(total_spent) as ratio
from cte
group by city
having sum(Gold_amount) is not null
order by ratio
-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)


with cte as (
select city,exp_type, sum(amount) as total_amount from credit_card_transcations
group by city,exp_type )
select city , max(case when rn_asc=1 then exp_type end) as lowest_exp_type
, min(case when rn_desc=1 then exp_type end) as highest_exp_type
from
(select *
,rank() over(partition by city order by total_amount desc) rn_desc
,rank() over(partition by city order by total_amount asc) rn_asc
from cte) A
group by city;


-- 6- write a query to find percentage contribution of spends by females for each expense type


select exp_type,
sum(case when gender='F' then amount else 0 end)*100.0/sum(amount) as percentage_female_contribution
from credit_card_transcations
group by exp_type
order by percentage_female_contribution desc;



-- 7- which card and expense type combination saw highest month over month growth in Jan-2014
with cte as (
select card_type, exp_type, year(transaction_date) as yr, MONTH(transaction_date) as mth, sum(amount) as curr_month_amount
from credit_card_transcations 
group by card_type, exp_type, year(transaction_date), MONTH(transaction_date)
),
previous_growth_cte as (
select *, lag(curr_month_amount,1, 0) over(partition by card_type, exp_type order by yr, mth) as previous_month_amount
from cte )
select top 1 *, (curr_month_amount - previous_month_amount) *1.0/previous_month_amount as mom_growth
from previous_growth_cte
where yr = 2014 and mth = 01
order by mom_growth desc;



-- 8- during weekends which city has highest total spend to total no of transcations ratio 

select top 1 city, sum(amount) *1.0/ count(1) as ratio
from credit_card_transcations
where DATEPART(weekday, transaction_date) in (1, 7)
group by city 
order by ratio desc


-- 9- which city took least number of days to reach its 500th transaction after the first transaction in that city
with cte as (
select *, FIRST_VALUE(transaction_date) over(partition by city order by transaction_date) as first_transaction, ROW_NUMBER() over(partition by city order by transaction_date) as rn
from credit_card_transcations )
select top 1 city, transaction_date, first_transaction, DATEDIFF(day, first_transaction, transaction_date) as days_taken_to_complete_500_transactions 
from cte 
where rn = 500
order by days_taken_to_complete_500_transactions;
