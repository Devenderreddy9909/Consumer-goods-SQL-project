/*  1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.*/

select  distinct market 
from dim_customer 
where customer= 'Atliq Exclusive' and region = 'APAC';

/* 2. What is the percentage of unique product increase in 2021 vs. 2020? The
       final output contains these fields,
	   unique_products_2020
	   nique_products_2021
	   percentage_chg */

with unique_products as (
select  fiscal_year,count(distinct product_code) as unique_products 
from fact_sales_monthly 
group by fiscal_year)

select u_20.unique_products as unique_products_2020,
       u_21.unique_products as unique_products_2021,
	   round((u_21.unique_products - u_20.unique_products) /u_20.unique_products  *100 ,2) as percentage_chg
from unique_products u_20
join unique_products u_21
on  u_20.fiscal_year = 2020 and u_21.fiscal_year= 2021;

## or ##


SELECT X.unique_products_2020 AS unique_product_2020, Y.unique_products_2021 AS unique_products_2021, 
ROUND((unique_products_2021-unique_products_2020)*100/unique_products_2020, 2) AS percentage_chg
FROM
     (
      (SELECT COUNT(DISTINCT(product_code)) AS unique_products_2020 FROM fact_sales_monthly
      WHERE fiscal_year = 2020) X,
      (SELECT COUNT(DISTINCT(product_code)) AS unique_products_2021 FROM fact_sales_monthly
      WHERE fiscal_year = 2021) Y 
	 );

 /* 3. Provide a report with all the unique product counts for each segment and
	    sort them in descending order of product counts. 
	      The final output contains 2 fields,segment
			product_count */

select segment , count(distinct product_code) as product_count  from dim_product group by segment order by product_count desc;

 /*4. Follow-up : Which segment had the most increase in unique products in
 2021 vs 2020 ? The final output contains these fields ,
 segment product_count_2020 product_count_2021  difference*/



with product_count as (
select  segment,fiscal_year,count(distinct fm.product_code) as product_count
from fact_sales_monthly fm inner join dim_product dp
on fm.product_code=dp.product_code
group by fiscal_year, segment)

select p_20.segment ,p_20.product_count as product_count_2020,
p_21.product_count as product_count_2021,
(p_21.product_count-p_20.product_count) as diff
from product_count p_20
 join product_count p_21
where  p_20.fiscal_year = 2020 and p_21.fiscal_year= 2021
 and p_20.segment = p_21.segment
 order by diff desc;


## or ##

WITH CTE1 AS 
	(SELECT P.segment AS A , FS.fiscal_year, COUNT(DISTINCT(FS.product_code)) AS B 
    FROM dim_product P join fact_sales_monthly FS
    WHERE P.product_code = FS.product_code
    GROUP BY FS.fiscal_year, P.segment
    HAVING FS.fiscal_year = "2020"),
CTE2 AS
    (
	SELECT P.segment AS C , FS.fiscal_year, COUNT(DISTINCT(FS.product_code)) AS D 
    FROM dim_product P, fact_sales_monthly FS
    WHERE P.product_code = FS.product_code
    GROUP BY FS.fiscal_year, P.segment
    HAVING FS.fiscal_year = "2021"
    )     
    
SELECT CTE1.A AS segment, CTE1.B AS product_count_2020, CTE2.D AS product_count_2021, (CTE2.D-CTE1.B) AS difference  
FROM CTE1 join CTE2
on CTE1.A = CTE2.C ;

 /* 5. Get the products that have the highest and lowest manufacturing costs.
        The final output should contain these fields,
             product_code  product  manufacturing_cost  */

select dp.product_code,dp.product,cost_year,  fm.manufacturing_cost 
from dim_product dp inner join fact_manufacturing_cost fm
on dp.product_code=fm.product_code 
where manufacturing_cost in (select max(manufacturing_cost) from fact_manufacturing_cost
 union 
 select min(manufacturing_cost) from fact_manufacturing_cost)
order by manufacturing_cost desc;



/*  6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct 
        for the fiscal year 2021 and in the Indian market. 
                The final output contains these fields, 
                      customer_code customer average_discount_percentage  */

select fp.customer_code,customer,round(avg(fp.pre_invoice_discount_pct),4) as avg_pre_invoice 
from dim_customer dm 
inner join fact_pre_invoice_deductions fp on dm.customer_code=fp.customer_code 
where fiscal_year = 2021 and market= 'India'
group by fp.customer_code, customer 
order by avg_pre_invoice desc 
limit 5;

/* 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
        This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
           The final report contains these columns: Month Year Gross sales Amount */

with cte1 as (
select concat( monthname(date),' ( ' ,year(date),' )') as Month, fm.fiscal_year, (sold_quantity*gross_price) as Gross_sales_amount 
from fact_sales_monthly  fm
join fact_gross_price fp on fm.product_code= fp.product_code
join dim_customer dm  on  dm.customer_code= fm.customer_code
where customer= 'Atliq Exclusive'  
order by Gross_sales_amount desc)

select Month, fiscal_year, round(concat((sum(Gross_sales_amount)/1000000),  'M'),2) as Gross_sales_amount 
from cte1 
group by Month,fiscal_year 
order by fiscal_year;


/* 8. In which quarter of 2020, got the maximum total_sold_quantity? 
       The final output contains these fields sorted by the total_sold_quantity,
          Quarter total_sold_quantity */


select 
case
    when date between '2019-09-01' and '2019-11-30' then 'Q1'  
    when date between '2019-12-01' and '2020-02-28' then 'Q2'
    when date between '2020-03-01' and '2020-05-31' then 'Q3'
    when date between '2020-06-01' and '2020-08-31' then 'Q4'
    end as Quarter,
  round(SUM(sold_quantity)/1000000,2)as total_sold_quantity
from fact_sales_monthly
where fiscal_year = 2020
group by  Quarter
order by total_sold_quantity desc ;



 /*  9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
          The final output contains these fields, channel gross_sales_mln percentage  */
 
with cte1 as (
select channel , fm.fiscal_year ,concat(round(sum((sold_quantity*gross_price)/1000000 ),2),'M')as gross_sales_mln 
from fact_sales_monthly fm  
join fact_gross_price fp on fm.product_code= fp.product_code 
join dim_customer  dm on dm.customer_code= fm.customer_code  
where fm.fiscal_year= 2021
group by channel, fm.fiscal_year)

select channel, fiscal_year , gross_sales_mln,concat( round(gross_sales_mln/(sum(gross_sales_mln) over ()) *100,2),'%')  as gross_sales_percentage from cte1;


/*10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
         The final output contains these fields, division product_code product total_sold_quantity rank_order */
  
  with cte1 as (
  select division,fm.product_code,product,sum(sold_quantity) ,
  rank ()over(partition by division order by sum(sold_quantity)desc) as rnk 
  from fact_sales_monthly fm 
  join dim_product dm on fm.product_code= dm.product_code 
  where fiscal_year= 2021 
  group by division,fm.product_code,product)
  
  select * from cte1 where rnk in (1,2,3);

