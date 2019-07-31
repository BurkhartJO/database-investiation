/* Query 1 - How do film rental stores compare with monthly rental fulfillment? */
SELECT rental_month
	, rental_year
	, store_id
	, COUNT(rental_id) AS rental_count
FROM (SELECT DATE_PART('month', r.rental_date) AS rental_month
		, DATE_PART('year', r.rental_date) AS rental_year
		, s.store_id
		, r.rental_id
	FROM rental r
	JOIN staff USING (staff_id)
	JOIN store s USING (store_id)) t1
GROUP BY 1,2,3
ORDER BY 4 DESC;

/* Query 2 - Which customers have spent the most on rentals and when? */
WITH top10 AS (SELECT c.customer_id
		, CONCAT(c.first_name, ' ', c.last_name) AS customer_name
		, SUM(p.amount) AS pay_total_amt
	FROM customer c
	JOIN payment p USING (customer_id)
	WHERE DATE_PART('year', p.payment_date) = 2007
	GROUP BY 1,2
	ORDER BY 3 DESC
	LIMIT 10)

SELECT DATE_TRUNC('month', p.payment_date) AS payment_date
	, top10.customer_name
	, COUNT(p.payment_id) AS pay_monthly_count
	, SUM(p.amount) AS pay_total_amt
FROM payment p
JOIN top10 USING (customer_id)
GROUP BY 2,1
ORDER BY 2;

/* Query 3 - Which of the top 10 customers has paid the most difference in terms of rental payments during 2007? */
WITH top10 AS (SELECT c.customer_id
		, CONCAT(c.first_name, ' ', c.last_name) AS customer_name
		, SUM(p.amount) AS pay_total_amt
	FROM customer c
	JOIN payment p USING (customer_id)
	WHERE DATE_PART('year', p.payment_date) = 2007
	GROUP BY 1,2
	ORDER BY 3 DESC
	LIMIT 10),

	t2 AS (SELECT top10.customer_id
		, DATE_TRUNC('month', p.payment_date) AS payment_date
		, top10.customer_name
		, COUNT(p.payment_id) AS pay_monthly_count
		, SUM(p.amount) AS pay_total_amt
	FROM payment p
	JOIN top10 USING (customer_id) 
	GROUP BY 2,1,3
	ORDER BY 2)

SELECT t2.payment_date
	, t2.customer_name
	, t2.pay_total_amt
	, LEAD(t2.pay_total_amt) OVER (PARTITION BY customer_name ORDER BY t2.pay_total_amt) AS lead_amt
	, LEAD(t2.pay_total_amt) OVER (PARTITION BY customer_name ORDER BY t2.pay_total_amt) - t2.pay_total_amt AS lead_difference
FROM t2
ORDER BY 2,1;

/* Query 4 - Which family-friendly category experienced the most rentals during all four quarters in 2007? */
WITH t1 AS (SELECT c.name 
		, NTILE(4) OVER (ORDER BY f.rental_duration) AS quartile
		, r.rental_id
	FROM film f
	JOIN film_category USING (film_id)
	JOIN category c USING (category_id)
	JOIN inventory USING (film_id)
	JOIN rental r USING (inventory_id)
	WHERE c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music'))

SELECT name
	, CASE WHEN quartile = 1 THEN 'first_quarter' 
		WHEN quartile = 2 THEN 'second_quarter' 
		WHEN quartile = 3 THEN 'third_quarter' 
		ELSE 'final_quarter' END AS rental_length_category
	, COUNT(rental_id) AS rental_count
FROM t1 
GROUP BY 1,2
ORDER BY 2,3;
