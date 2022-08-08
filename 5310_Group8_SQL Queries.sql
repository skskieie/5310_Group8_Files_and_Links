---- Orders ----
select sum(total_cost) as gmv
from orders;


-- 1. The GMV and Order Count in each State? 
select trim(substring(right(ship_address, 9), 0,4)) as shipping_state,
       count(*) as order_count,
       sum(total_cost) as gmv
from orders as o
group by shipping_state
order by order_count desc;

-- 2. The monthly GMV, order Count, and Average Unit (Order) Price?
select *,
       round(gmv/order_count, 2) as avg_unit_price
from (
SELECT TO_CHAR(order_date, 'yyyy/mm') as order_month,
       sum(total_cost) as gmv,
       count(*) as order_count
from orders
group by order_month
order by order_month) a;


---- Users ----

-- 1. What percentage of total sales do the top 20% of users with most spending account for?
select *, 
        round(top_20_percent_users_spending_gmv/gmv,2) as top_20_percent_user_comsumption_amount_gmv_for_total_gmv
from
        (select sum(total_cost) as gmv,
                (select sum(gmv) as top_20_percent_users_spending_gmv
                from
                    (SELECT user_id,
                            sum(total_cost) as gmv
                    from orders o
                    left join order_placed_user ou
                        on o.order_id = ou.order_id
                    group by user_id
                    order by gmv desc
                    limit (select count(1)*0.2
                           from users)) a)
        from orders) b;

-- 2. The monthly GMV, order count and average unit (order) price regarding each age group?
select *,
       round(gmv/order_count, 2) as avg_unit_price
from (
    SELECT TO_CHAR(order_date, 'yyyy/mm') as order_month,
            case when (user_age >= 15 and user_age < 25) then '15-24'
                when (user_age >= 25 and user_age < 35) then '25-34'
                when (user_age >= 35 and user_age < 45) then '35-44'
                when (user_age >= 35 and user_age < 55) then '45-54'
                when (user_age >= 55 and user_age < 65) then '55-64' 
                when (user_age >= 65 and user_age <= 80) then '65-80' 
                else '>80' end as user_age_range,
            sum(total_cost) as gmv,
            count(*) as order_count
    from orders o
    left join order_placed_user ou
        on o.order_id = ou.order_id
    left join users u
        on ou.user_id = u.user_id
        group by user_age_range,
                   order_month
        order by user_age_range,order_month) a;

-- 3. The top 5 products and top 5 options in these products regarding sales quantity in each age group?
select * from
    (select dense_rank() over (partition by user_age_range order by sales_volumn desc) as rank,
           *
    from (
            SELECT 
                   case when (user_age >= 15 and user_age < 25) then '15-24'
                        when (user_age >= 25 and user_age < 35) then '25-34'
                        when (user_age >= 35 and user_age < 45) then '35-44'
                        when (user_age >= 35 and user_age < 55) then '45-54'
                        when (user_age >= 55 and user_age < 65) then '55-64' 
                        when (user_age >= 65 and user_age <= 80) then '65-80' 
                        else '>80' end as user_age_range,
                        cate.category_id,
                        cate.category_name,
                        p.product_id,
                        p.product_name,
                        op.option_id,
                        option_name,
                        sum(total_cost) as gmv,
                        count(*) as order_count,
                        sum(order_option_quantity) as sales_volumn
            from orders o
                left join order_placed_user ou
                        on o.order_id = ou.order_id
                left join users u
                    on ou.user_id = u.user_id
                left join order_has_product op
                    on o.order_id = op.order_id
                left join products p
                    on op.product_id = p.product_id
                left join categories cate
                    on p.category_id = cate.category_id
                left join options option
                    on op.option_id = option.option_id
                group by user_age_range, cate.category_id,cate.category_name,p.product_id,p.product_name,op.option_id,option_name
                order by user_age_range) a) b
where rank <= 5;

-- 4. What's the difference in average customer unit price between users with items in their shopping cart and users without items in their shopping cart?
select aa.user_age_range,
       shoppingcart_is_empty_avg_unit_price,
       shoppingcart_has_product_avg_unit_price,
       (shoppingcart_has_product_avg_unit_price-shoppingcart_is_empty_avg_unit_price) as notempty_minus_empty
from
(select user_age_range,
       round(gmv/order_count, 2) as shoppingcart_is_empty_avg_unit_price
from (
        SELECT 
                case when (user_age >= 15 and user_age < 25) then '15-24'
                    when (user_age >= 25 and user_age < 35) then '25-34'
                    when (user_age >= 35 and user_age < 45) then '35-44'
                    when (user_age >= 35 and user_age < 55) then '45-54'
                    when (user_age >= 55 and user_age < 65) then '55-64' 
                    when (user_age >= 65 and user_age <= 80) then '65-80' 
                    else '>80' end as user_age_range,
                sum(total_cost) as gmv,
                count(*) as order_count
        from orders o
        left join order_placed_user ou
            on o.order_id = ou.order_id
        left join users u
            on ou.user_id = u.user_id
        left join user_shopping_cart usc
            on u.user_id = usc.user_id
        left join shoppingcarts sc
            on usc.shopping_cart_id = sc.shopping_cart_id
        where shopping_cart_status = 0
            group by user_age_range
            order by user_age_range) a) aa
join 
(select user_age_range,
       round(gmv/order_count, 2) as shoppingcart_has_product_avg_unit_price
from (
    SELECT 
            case when (user_age >= 15 and user_age < 25) then '15-24'
                when (user_age >= 25 and user_age < 35) then '25-34'
                when (user_age >= 35 and user_age < 45) then '35-44'
                when (user_age >= 35 and user_age < 55) then '45-54'
                when (user_age >= 55 and user_age < 65) then '55-64' 
                when (user_age >= 65 and user_age <= 80) then '65-80' 
                else '>80' end as user_age_range,
            sum(total_cost) as gmv,
            count(*) as order_count
    from orders o
    left join order_placed_user ou
        on o.order_id = ou.order_id
    left join users u
        on ou.user_id = u.user_id
    left join user_shopping_cart usc
        on u.user_id = usc.user_id
    left join shoppingcarts sc
        on usc.shopping_cart_id = sc.shopping_cart_id
    where shopping_cart_status = 1
        group by user_age_range
        order by user_age_range) b) bb
on aa.user_age_range = bb.user_age_range;


---- Products ----

-- 1. Top three categories with the most order quantity? 
select rank,
       category_id,
       category_name,
       sales_volumn
from 
    (select *, 
           dense_rank() over (order by sales_volumn desc) as rank
    from
        (select category_id,
                category_name,
                sum(order_option_quantity) as sales_volumn
         from
                (select o.order_id,  
                        p.category_id, 
                        cate.category_name,
                        op.product_id,
                        p.product_name,
                        op.option_id, 
                        option.option_id,
                        op.order_option_quantity,
                        o.total_cost
                from orders as o
                left join order_has_product as op
                    on o.order_id = op.order_id
                left join products p
                    on op.product_id = p.product_id
                left join categories as cate
                    on p.category_id = cate.category_id
                left join options as option
                    on op.option_id = option.option_id) a 
            group by category_id, category_name) b) c
    where rank <=3; 

-- 2. What are the three products purchased most frequently in these three categories? 
-- What are the three options that have been purchased the most in 3 products?
-- Top 3 Products:
select *
from 
    (select *, 
           dense_rank() over (partition by category_id order by sales_volumn desc) as rank
    from
        (select category_id,
                category_name,
                product_id,
                product_name,
                sum(order_option_quantity) as sales_volumn
         from
                (select o.order_id,  
                        p.category_id, 
                        cate.category_name,
                        op.product_id,
                        p.product_name,
                        op.option_id, 
                        option.option_name,
                        op.order_option_quantity,
                        o.total_cost
                from orders as o
                left join order_has_product as op
                    on o.order_id = op.order_id
                left join products p
                    on op.product_id = p.product_id
                left join categories as cate
                    on p.category_id = cate.category_id
                left join options as option
                    on op.option_id = option.option_id) a 
            group by category_id, category_name, product_id,product_name) b) c
    where rank <=3;

-- Top 3 Options:
select option_rank, 
       category_id,
       category_name,
       product_id,
       product_name,
       option_id, 
       option_name,
       sales_volumn
        from 
            (select *, 
                dense_rank() over (partition by product_id order by sales_volumn desc) as option_rank
            from
                (select category_id,
                        category_name,
                        product_id,
                        product_name,
                        option_id, 
                        option_name,
                        sum(order_option_quantity) as sales_volumn
                from
                        (select o.order_id,  
                                p.category_id, 
                                cate.category_name,
                                op.product_id,
                                p.product_name,
                                op.option_id, 
                                option.option_name,
                                op.order_option_quantity,
                                o.total_cost
                        from orders as o
                        left join order_has_product as op
                            on o.order_id = op.order_id
                        left join products p
                            on op.product_id = p.product_id
                        left join categories as cate
                            on p.category_id = cate.category_id
                        left join options as option
                            on op.option_id = option.option_id) a 
                    group by category_id, category_name, product_id,product_name,option_id, option_name) b) c
            where product_id in
            (select product_id
                    from 
                        (select *, 
                            dense_rank() over (partition by category_id order by sales_volumn desc) as rank
                        from
                            (select category_id,
                                    category_name,
                                    product_id,
                                    product_name,
                                    sum(order_option_quantity) as sales_volumn
                            from
                                    (select o.order_id,  
                                            p.category_id, 
                                            cate.category_name,
                                            op.product_id,
                                            p.product_name,
                                            op.option_id, 
                                            option.option_name,
                                            op.order_option_quantity,
                                            o.total_cost
                                    from orders as o
                                    left join order_has_product as op
                                        on o.order_id = op.order_id
                                    left join products p
                                        on op.product_id = p.product_id
                                    left join categories as cate
                                        on p.category_id = cate.category_id
                                    left join options as option
                                        on op.option_id = option.option_id) a 
                                group by category_id, category_name, product_id,product_name) b) c
                        where rank <=3) 
         and option_rank <=3;


-- 3. What are the top 10 options in the remaining inventory, and their related categories?
select * 
from
    (select 
        dense_rank() over (order by inventory desc) as rank,
        *
        from (select po.inventory, 
                        p.category_id, 
                        cate.category_name,
                        po.product_id,
                        p.product_name,
                        po.option_id, 
                        option.option_name
                from product_has_options as po
                left join products p
                    on po.product_id = p.product_id
                left join categories as cate
                    on p.category_id = cate.category_id
                left join options as option
                    on po.option_id = option.option_id) a) b
    where rank <= 10;

    
---- Vendors ----

-- 1. How many options are on sale for each vendor, and what is the on_sale proportion?
select v.vendor_id,
       v.vendor_name,
       count(on_sale),
       (case when a.number_of_on_sale is null then 0 else a.number_of_on_sale end),
       round((case when a.number_of_on_sale is null then 0 else a.number_of_on_sale end )*1.00
       /count(on_sale),2) as percent_of_on_sale_options
from product_has_options po
left join products p
    on po.product_id = p.product_id
left join product_sold_vendor pv
    on p.product_id = pv.product_id
left join vendors as v
    on pv.vendor_id = v.vendor_id
left join (select v.vendor_id,
                  v.vendor_name,
                  count(on_sale) as number_of_on_sale
            from product_has_options po
            left join products p
                on po.product_id = p.product_id
            left join product_sold_vendor pv
                on p.product_id = pv.product_id
            left join vendors as v
                on pv.vendor_id = v.vendor_id
            where on_sale = 1
            group by v.vendor_id,
                     v.vendor_name) a
    on pv.vendor_id = a.vendor_id
group by v.vendor_id,
         v.vendor_name,
         a.number_of_on_sale;

-- 2. Trendy products of each vendor (eg:5G) sales?
select pv.vendor_id,
       vendor_name,
       p.product_id,
       product_name,
       descriptions,
       sales_volumn
from products as p
left join product_sold_vendor as pv
    on p.product_id = pv.product_id
left join vendors v
    on pv.vendor_id = v.vendor_id
left join (select sum(order_option_quantity) as sales_volumn,
                  product_id
           from order_has_product op
           group by product_id) a
    on p.product_id = a.product_id
where descriptions like '%5G%'
order by sales_volumn desc;

-- 3. Are there more orders from products on-sale among vendors? 
select case when on_sale = 1 then 'Yes' else 'NO' end as on_sale,
            sales_volumn_rank, 
            selling_price_rank,
            category_id,
            category_name,
            product_id,
            product_name,
            sales_volumn,
            selling_price
                from 
                    (select *, 
                        dense_rank() over (partition by category_id order by sales_volumn desc) as sales_volumn_rank,
                        dense_rank() over (partition by category_id order by selling_price desc) as selling_price_rank
                    from
                        (select category_id,
                                category_name,
                                product_id,
                                product_name,
                                sum(order_option_quantity) as sales_volumn,
                                selling_price,
                                on_sale
                        from
                                (select o.order_id,  
                                        p.category_id, 
                                        cate.category_name,
                                        op.product_id,
                                        p.product_name,
                                        op.option_id, 
                                        option.option_name,
                                        op.order_option_quantity,
                                        o.total_cost,
                                        selling_price,
                                        on_sale
                                from orders as o
                                left join order_has_product as op
                                    on o.order_id = op.order_id
                                left join products p
                                    on op.product_id = p.product_id
                                left join categories as cate
                                    on p.category_id = cate.category_id
                                left join options as option
                                    on op.option_id = option.option_id
                                left join product_has_options po
                                    on p.product_id = po.product_id) a 
                                group by category_id, category_name, product_id,product_name, selling_price,on_sale) b) c;

-- 4. Under the same discount, do more expensive products has more sale quantity than cheaper products?
select sales_volumn_rank, 
       selling_price_rank,
       category_id,
       category_name,
       product_id,
       product_name,
       sales_volumn,
       selling_price
        from 
            (select *, 
                dense_rank() over (partition by category_id order by sales_volumn desc) as sales_volumn_rank,
                dense_rank() over (partition by category_id order by selling_price desc) as selling_price_rank
            from
                (select category_id,
                        category_name,
                        product_id,
                        product_name,
                        sum(order_option_quantity) as sales_volumn,
                        selling_price
                from
                        (select o.order_id,  
                                p.category_id, 
                                cate.category_name,
                                op.product_id,
                                p.product_name,
                                op.option_id, 
                                option.option_name,
                                op.order_option_quantity,
                                o.total_cost,
                                selling_price
                        from orders as o
                        left join order_has_product as op
                            on o.order_id = op.order_id
                        left join products p
                            on op.product_id = p.product_id
                        left join categories as cate
                            on p.category_id = cate.category_id
                        left join options as option
                            on op.option_id = option.option_id
                        left join product_has_options po
                            on p.product_id = po.product_id) a 
                        group by category_id, category_name, product_id,product_name, selling_price) b
                        where b.product_id in (select po.product_id 
                                              from product_has_options po
                                              where on_sale = 1)) c；
                                              

