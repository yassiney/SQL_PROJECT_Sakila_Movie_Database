/* Query 1 - What is the number of rental orders for the two stores each month for all years*/
SELECT
    sr.store_id AS id_store,
    DATE_PART('month', r.rental_date) AS rental_month,
    DATE_PART('year', r.rental_date) AS rental_year,
    COUNT(*) AS count_rental
FROM store AS sr
    JOIN staff AS sf
		ON sr.store_id = sf.store_id
    JOIN rental AS r
		ON r.staff_id = sf.staff_id
GROUP BY
    id_store,
    rental_month,
    rental_year
ORDER BY
    count_rental DESC;
/* Query 2 - What are the monthly payments for the top 10 customers of 2007?*/
WITH top10 AS (
    SELECT
        c.customer_id,
        SUM(p.amount) AS total_amount
    FROM
        customer AS c
        JOIN payment AS p
				ON c.customer_id = p.customer_id
    GROUP BY
        c.customer_id
    ORDER BY
        total_amount DESC
    LIMIT 10
)
SELECT
  	(first_name || ' ' || last_name) AS full_name,
		DATE_TRUNC('month', payment_date) AS pay_date_mon,
		COUNT(p.amount) AS pay_count_mon,
		SUM(p.amount) AS pay_amount_mon
FROM
    top10
    JOIN customer AS c
		ON top10.customer_id = c.customer_id
    JOIN payment AS p
		ON p.customer_id = c.customer_id
WHERE
    payment_date >= '2007-01-01'
    AND payment_date < '2008-01-01'
GROUP BY
    full_name,
    pay_date_mon
ORDER BY
    full_name,
    pay_date_mon;
/* Query 3 - What is the total number of rental orders for each category?  Divide it into four quartiles based on the total number of orders*/
SELECT
    category,
    rental_total,
    NTILE(4) OVER (ORDER BY rental_total) AS quartile
FROM (
    SELECT
        c.name AS category,
        COUNT(*) AS rental_total
    FROM
        category AS c
        JOIN film_category AS fc
				ON c.category_id = fc.category_id
        JOIN film AS f
				ON fc.film_id = f.film_id
        JOIN inventory AS i
				ON i.film_id = f.film_id
        JOIN rental AS r
				ON i.inventory_id = r.inventory_id
    GROUP BY
        category) AS tab1
ORDER BY
    rental_total DESC;
/* Query 4 - For each of the top 3 paying customers, what is the difference across their monthly payments during 2007 */
WITH top3 AS (
    SELECT
        c.customer_id,
        SUM(p.amount) AS total_amount
    FROM
        customer AS c
        JOIN payment AS p
				ON c.customer_id = p.customer_id
    GROUP BY
        c.customer_id
    ORDER BY
        total_amount DESC
    LIMIT 3),
tab2 AS (
    SELECT
        (first_name || ' ' || last_name) AS full_name,
        DATE_TRUNC('month', payment_date) AS pay_date_mon,
        COUNT(p.amount) AS pay_count_mon,
        SUM(p.amount) AS pay_amount_mon
    FROM
        top3
        JOIN customer AS c
				ON top3.customer_id = c.customer_id
        JOIN payment AS p
				ON p.customer_id = c.customer_id
    WHERE
        payment_date >= '2007-01-01'
        AND payment_date < '2008-01-01'
    GROUP BY
        full_name,
        pay_date_mon
    ORDER BY
        full_name,
        pay_date_mon
)
SELECT
    full_name,
    pay_date_mon,
    pay_amount_mon,
    LAG(pay_amount_mon) OVER (
														PARTITION BY full_name
														ORDER BY pay_date_mon) AS lag,
		pay_amount_mon - LAG(pay_amount_mon) OVER (
																						PARTITION BY full_name
																						ORDER BY pay_date_mon) AS mon_diff
FROM
    tab2;
