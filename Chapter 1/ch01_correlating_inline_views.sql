/* ***************************************************** **
   ch01_correlating_inline_views.sql
   
   Companion script for Practical Oracle SQL, Apress 2020
   by Kim Berg Hansen, https://www.kibeha.dk
   Use at your own risk
   *****************************************************
   
   Chapter 1
   Correlating Inline Views
   
   To be executed in schema PRACTICAL
** ***************************************************** */

/* -----------------------------------------------------
   sqlcl formatting setup
   ----------------------------------------------------- */

set pagesize 80
set linesize 80
set sqlformat ansiconsole

/* -----------------------------------------------------
   Chapter 1 example code
   ----------------------------------------------------- */

-- Listing 1-1. The yearly sales of the 3 beers from Balthazar Brauerei.
SELECT
    bp.brewery_name,
    bp.product_id AS p_id,
    bp.product_name,
    ys.yr,
    ys.yr_qty
FROM
         brewery_products bp
    JOIN yearly_sales ys ON ys.product_id = bp.product_id
WHERE
    bp.brewery_id = 518
ORDER BY
    bp.product_id,
    ys.yr;

-- Listing 1-2. Retrieving two columns from the best-selling year per beer.
SELECT
    bp.brewery_name,
    bp.product_id AS p_id,
    bp.product_name,
    (
        SELECT
            ys.yr
        FROM
            yearly_sales ys
        WHERE
            ys.product_id = bp.product_id
        ORDER BY
            ys.yr_qty DESC
        FETCH FIRST ROW ONLY
    )             AS yr,
    (
        SELECT
            ys.yr_qty
        FROM
            yearly_sales ys
        WHERE
            ys.product_id = bp.product_id
        ORDER BY
            ys.yr_qty DESC
        FETCH FIRST ROW ONLY
    )             AS yr_qty
FROM
    brewery_products bp
WHERE
    bp.brewery_id = 518
ORDER BY
    bp.product_id;

-- Listing 1-3. Using just a single scalar sub-query and value concatenation.
SELECT
    brewery_name,
    product_id                      AS p_id,
    product_name,
    TO_NUMBER(substr(yr_qty_str,
                     1,
                     instr(yr_qty_str, ';') - 1)) AS yr,
    TO_NUMBER(substr(yr_qty_str,
                     instr(yr_qty_str, ';') + 1)) AS yr_qty
FROM
    (
        SELECT
            bp.brewery_name,
            bp.product_id,
            bp.product_name,
            (
                SELECT
                    ys.yr
                    || ';'
                    || ys.yr_qty
                FROM
                    yearly_sales ys
                WHERE
                    ys.product_id = bp.product_id
                ORDER BY
                    ys.yr_qty DESC
                FETCH FIRST ROW ONLY
            ) AS yr_qty_str
        FROM
            brewery_products bp
        WHERE
            bp.brewery_id = 518
    )
ORDER BY
    product_id;

-- Listing 1-4. Using analytic function to be able to retrieve all columns if desired.
SELECT
    brewery_name,
    product_id AS p_id,
    product_name,
    yr,
    yr_qty
FROM
    (
        SELECT
            bp.brewery_name,
            bp.product_id,
            bp.product_name,
            ys.yr,
            ys.yr_qty,
            ROW_NUMBER()
            OVER(PARTITION BY bp.product_id
                 ORDER BY
                     ys.yr_qty DESC
            ) AS rn
        FROM
                 brewery_products bp
            JOIN yearly_sales ys ON ys.product_id = bp.product_id
        WHERE
            bp.brewery_id = 518
    )
WHERE
    rn = 1
ORDER BY
    product_id;

-- Listing 1-5. Achieving the same with a lateral in-line view.
select
   bp.brewery_name
 , bp.product_id as p_id
 , bp.product_name
 , top_ys.yr
 , top_ys.yr_qty
from brewery_products bp
cross join lateral(
   select
      ys.yr
    , ys.yr_qty
   from yearly_sales ys
   where ys.product_id = bp.product_id
   order by ys.yr_qty desc
   fetch first row only
) top_ys
where bp.brewery_id = 518
order by bp.product_id;

-- Traditional style from clause without ANSI style cross join

select
   bp.brewery_name
 , bp.product_id as p_id
 , bp.product_name
 , top_ys.yr
 , top_ys.yr_qty
from brewery_products bp
, lateral(
   select
      ys.yr
    , ys.yr_qty
   from yearly_sales ys
   where ys.product_id = bp.product_id
   order by ys.yr_qty desc
   fetch first row only
) top_ys
where bp.brewery_id = 518
order by bp.product_id;

-- Combining both lateral and join predicates in the on clause

select
   bp.brewery_name
 , bp.product_id as p_id
 , bp.product_name
 , top_ys.yr
 , top_ys.yr_qty
from brewery_products bp
join lateral(
   select
      ys.yr
    , ys.yr_qty
   from yearly_sales ys
   where ys.product_id = bp.product_id
   order by ys.yr_qty desc
   fetch first row only
) top_ys
   on 1=1
where bp.brewery_id = 518
order by bp.product_id;

-- Listing 1-6. The alternative syntax cross apply

select
   bp.brewery_name
 , bp.product_id as p_id
 , bp.product_name
 , top_ys.yr
 , top_ys.yr_qty
from brewery_products bp
cross apply(
   select
      ys.yr
    , ys.yr_qty
   from yearly_sales ys
   where ys.product_id = bp.product_id
   order by ys.yr_qty desc
   fetch first row only
) top_ys
where bp.brewery_id = 518
order by bp.product_id;

-- Listing 1-7. Using outer apply when you need outer join functionality

select
   bp.brewery_name
 , bp.product_id as p_id
 , bp.product_name
 , top_ys.yr
 , top_ys.yr_qty
from brewery_products bp
outer apply(
   select
      ys.yr
    , ys.yr_qty
   from yearly_sales ys
   where ys.product_id = bp.product_id
   and ys.yr_qty < 400
   order by ys.yr_qty desc
   fetch first row only
) top_ys
where bp.brewery_id = 518
order by bp.product_id;

-- Listing 1-8. Outer join with the lateral keyword

select
   bp.brewery_name
 , bp.product_id as p_id
 , bp.product_name
 , top_ys.yr
 , top_ys.yr_qty
from brewery_products bp
left outer join lateral(
   select
      ys.yr
    , ys.yr_qty
   from yearly_sales ys
   where ys.product_id = bp.product_id
   order by ys.yr_qty desc
   fetch first row only
) top_ys
   on top_ys.yr_qty < 500
where bp.brewery_id = 518
order by bp.product_id;

/* ***************************************************** */
