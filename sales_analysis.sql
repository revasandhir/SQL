USE mban_db;

-- Question 1. Top 3 Most Sold Items by Year-Month

-- In this query, we identified the top three best-selling articles each month
-- by calculating the total quantity sold and revenue generated for each article,
-- then grouping the data by year and month.
-- The result lists the year, month, rank, article name, quantity sold,
-- and total revenue for the top-ranked articles.


-- Create a CTE to calculate monthly sales and revenue for each article
WITH MonthlySales AS (
    SELECT
        YEAR(sale_datetime) AS year,  -- Extract the year from the sale datetime
        MONTH(sale_datetime) AS month, -- Extract the month from the sale datetime
        article, -- Select the article
        SUM(quantity) AS total_quantity, -- Calculate the total quantity sold
        SUM(quantity * unit_price) AS total_revenue -- Calculate the total revenue generated
    FROM assignment01.bakery_sales
    GROUP BY YEAR(sale_datetime), MONTH(sale_datetime), article -- Group by year, month, and article

),
-- Rank the articles within each month based on total quantity sold
RankedSales AS (
    SELECT
        year,
        month,
        article,
        total_quantity,
        total_revenue,
        RANK() OVER (PARTITION BY year, month ORDER BY total_quantity DESC) AS rank -- Rank articles by quantity within each month

    FROM MonthlySales
)
-- Select the top 3 articles for each month based on the rank
SELECT
    year,
    month,
    rank,
    article,
    total_quantity AS quantity,
    total_revenue AS revenue
FROM RankedSales
WHERE rank <= 3 -- Filter to include only the top 3 ranked articles
ORDER BY year, month, rank; -- Order the results by year, month, and rank



-- Question 2. Tickets with 5 or More Articles

-- In this query, we created a CTE to identify tickets from December 2021
-- that include 5 or more unique articles. Then join the CTE with
-- the main sales table to retrieve and display the ticket details,
-- such as the ticket number, article and quantity order by ticket number
-- and article.


-- CTE to find tickets with 5 or more unique articles in December 2021
WITH TicketCounts AS (
    SELECT
        ticket_number
    FROM
        assignment01.bakery_sales
    WHERE
        sale_date BETWEEN '2021-12-01' AND '2021-12-31' -- Only consider sales in December 2021
    GROUP BY
        ticket_number -- Group by ticket number
    HAVING
        COUNT(DISTINCT article) >= 5 -- Only include tickets with 5 or more unique articles
)
-- Main query to get ticket details and articles
SELECT
    s.ticket_number, -- Select the ticket number
    s.article, -- Select the article
    s.quantity -- Select the quantity of the article
FROM
    assignment01.bakery_sales AS s -- From the bakery_sales table
JOIN
    TicketCounts AS t -- Join with the CTE TicketCounts
ON
    s.ticket_number = t.ticket_number -- On matching ticket numbers
WHERE
    s.sale_date BETWEEN '2021-12-01' AND '2021-12-31' -- Only consider sales in December 2021
ORDER BY
    s.ticket_number, s.article; -- Order the results by ticket number and article






-- Question 3. Most Popular Hour of the Day for Sales

-- In this query, we determined the most popular hour for "Traditional Baguette" sales
-- in July 2022 by aggregating sales data by hour, ranking the total quantity sold each hour per day,
-- and then selecting the highest-ranked hour for each day.


-- Create a CTE to calculate total sales quantity by hour for each day in July 2022
WITH july2022_sales_by_hour AS (
    SELECT
        sale_date,
        DATEPART(HOUR, sale_datetime) AS sale_hour,
        SUM(quantity) AS total_quantity
    FROM
        assignment01.bakery_sales
    WHERE
        sale_date BETWEEN '2022-07-01' AND '2022-07-31'
        AND article = 'Traditional Baguette'
    GROUP BY
        sale_date,
        DATEPART(HOUR, sale_datetime)
),
-- Rank the hours within each day based on the total sales quantity
ranked_sales AS (
    SELECT
        sale_date,
        sale_hour,
        total_quantity,
       RANK() OVER (PARTITION BY sale_date ORDER BY total_quantity DESC) AS sale_rank
    FROM
        july2022_sales_by_hour
)
-- Select the most popular hour by returning rank 1 for each day
SELECT
    sale_date AS day,
    CAST(sale_hour AS VARCHAR) + '-' + CAST(sale_hour + 1 AS VARCHAR) AS most_popular_hour, -- format the hour range
    total_quantity AS quantity
FROM
    ranked_sales
WHERE
    sale_rank = 1
ORDER BY
    sale_date;



-- Question 4. Data Quality

-- Check for missing values using nullif
SELECT
    COUNT(*) - COUNT(NULLIF(sale_date, NULL)) AS missing_dates,
    COUNT(*) - COUNT(NULLIF(sale_time, NULL)) AS missing_times,
    COUNT(*) - COUNT(NULLIF(article, NULL)) AS missing_items,
    COUNT(*) - COUNT(NULLIF(Quantity, NULL)) AS missing_quantities,
    COUNT(*) - COUNT(NULLIF(unit_price, NULL)) AS missing_prices
FROM assignment01.bakery_sales;


-- Check for duplicate records
SELECT
    sale_date, sale_time, article, Quantity, unit_price, COUNT(*) AS num_duplicates
FROM assignment01.bakery_sales
GROUP BY sale_date, sale_time, article, Quantity, unit_price
HAVING COUNT(*) > 1;



-- Check for outliers in Quantity
SELECT
    MIN(Quantity) AS min_quantity,
    MAX(Quantity) AS max_quantity,
    AVG(Quantity) AS avg_quantity,
    STDEV(Quantity) AS stdev_quantity
FROM assignment01.bakery_sales;



-- Check for outliers in Price
SELECT
    MIN(unit_price) AS min_price,
    MAX(unit_price) AS max_price,
    AVG(unit_price) AS avg_price,
    STDEV(unit_price) AS stdev_price
FROM assignment01.bakery_sales;


-- Findings
-- 1. Missing Values: There are 5 missing values in the unit_price column
-- 2. Duplicates: There are 500 entries with duplicate records
-- 3. Outliers
--    Quantity:
--       Minimum value: -200 (indicating an error)
--       Maximum value: 200
--       Mean value: 1.54
--       Standard deviation: 1.29
--   Price:
--       Minimum value: 0.00
--       Maximum value: 60.00 (indicating an error)
--       Mean value: 1.66
--       Standard deviation: 1.72
-- The minimum value cannot be -200 for quantity, indicating there is an error here.
-- As well as this, a maximum value of 60 for price seems exceptionally high for goods from a bakery,
-- leading to believe there is a possible error here as well.
