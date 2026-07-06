use mavenmovies;
select * from film;

/*Business Question:
Findout  3 film	category	generates	the	most	total	revenue? */

SELECT	cat.name	AS	category,	SUM(p.amount)	AS	total_revenue
FROM	payment	p
JOIN	rental	r	ON	p.rental_id	=	r.rental_id
JOIN	inventory	i ON	r.inventory_id	=	i.inventory_id 
JOIN	film_category	fc	ON	i.film_id	=	fc.film_id
JOIN	category	cat	ON	fc.category_id	=	cat.category_id
GROUP	BY	cat.name
ORDER	BY	total_revenue	DESC
LIMIT	3;

/*Business Question: 
Identify	the	top	5	“best	customers”	by	total	spend,	and	their average	payment	amount */
SELECT	c.customer_id,	c.first_name,	c.last_name,
SUM(p.amount)	AS	total_spent,
AVG(p.amount)	AS	avg_payment
FROM	customer	c
JOIN	payment	p	ON	c.customer_id	=	p.customer_id
GROUP	BY	c.customer_id,	c.first_name,	c.last_name
ORDER	BY	total_spent	DESC
LIMIT	5;

/*Business Question: 
Find	which	staff	member	processed	the	most	payments and	how much	revenue	they	brought in */
SELECT	st.staff_id,	st.first_name,	st.last_name,
COUNT(p.payment_id)	AS	payments_processed,
SUM(p.amount)	AS	revenue_generated
FROM	staff	st
JOIN	payment	p	ON	st.staff_id	=	p.staff_id
GROUP	BY	st.staff_id,	st.first_name,	st.last_name
ORDER	BY	payments_processed	DESC;

/*Business Question: 
Find	the	busiest	month	for	rentals	(highest	number	of	rentals) */
SELECT	DATE_FORMAT(rental_date,	'%Y-%m')	AS	rental_month,
COUNT(*)	AS	rental_count
FROM	rental
GROUP	BY	rental_month
ORDER	BY	rental_count	DESC
LIMIT	1;

/*Business Question: 
Find	films	that	exist	in	inventory	but	have	never	been	rented (unused	stock)  */

SELECT  f.film_id,f.title,
COUNT(i.inventory_id) AS unused_copies
FROM film f
JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
WHERE r.rental_id IS NULL
GROUP BY f.film_id, f.title
ORDER BY unused_copies DESC;

/*Business Question:
Calculate,	for	each	country,	the	number	of	customers	and	total revenue	generated */

SELECT  co.country,
COUNT(DISTINCT c.customer_id) AS num_customers,
ROUND(SUM(p.amount),2) AS total_revenue
FROM country co
JOIN city ci ON co.country_id = ci.country_id
JOIN address a ON ci.city_id = a.city_id
JOIN customer c ON a.address_id = c.address_id
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY co.country
ORDER BY total_revenue DESC;

/*Business Question:
Find	the	average	number	of	rentals	per	active	customer vs.	inactive	customer */

SELECT	c.active,
ROUND(COUNT(r.rental_id)*1.0 /COUNT(DISTINCT c.customer_id),2) AS avg_rentals_per_customer
FROM	customer	c
LEFT	JOIN	rental	r	ON	c.customer_id	=	r.customer_id
GROUP	BY	c.active;

/*Business Question:
Find	the	actor	who	has	appeared in	the	most	films,	along	with the	count */

SELECT	a.actor_id,	a.first_name,	a.last_name,	COUNT(fa.film_id)	AS	film_count
FROM	actor a
JOIN	film_actor fa ON	a.actor_id = fa.actor_id
GROUP	BY	a.actor_id,	a.first_name,	a.last_name
ORDER	BY	film_count	DESC
LIMIT	1;

/*Business Question:
Using	a	CTE	and	window	function,	find	each	customer’s	first	and most	recent	rental	date	
and	total	rentals	in	one	query	(cohort-style analysis).*/

WITH	cust_rentals	AS	(
SELECT	customer_id,
MIN(rental_date)	AS	first_rental,
MAX(rental_date)	AS	last_rental,
COUNT(*)	AS	total_rentals
FROM	rental
GROUP	BY	customer_id
)
SELECT	c.first_name,	c.last_name,	cr.first_rental,	cr.last_rental,	cr.total_rentals,
DATEDIFF(cr.last_rental,	cr.first_rental)	AS	days_active
FROM	cust_rentals	cr
JOIN	customer c	ON	c.customer_id	=	cr.customer_id
ORDER	BY	total_rentals	DESC;

/*Business Question:
Build	a	query	that	flags	customers	as	“At	Risk”	if	their	last	rental
was	more	than	60	days	before	the	most	recent	rental	date	in	the
whole	dataset	(churn	analysis). */
WITH	last_global	AS	(
				SELECT	MAX(rental_date)	AS	max_date	FROM	rental
),
cust_last	AS	(
				SELECT	customer_id,	MAX(rental_date)	AS	last_rental
				FROM	rental
				GROUP	BY	customer_id
)
SELECT	c.customer_id,	c.first_name,	c.last_name,	cl.last_rental,
CASE
WHEN	DATEDIFF(lg.max_date,	cl.last_rental)	>	60 THEN	'At Risk'
ELSE	'Active'
END	AS	status
FROM	cust_last	cl
JOIN	customer c	ON	c.customer_id =	cl.customer_id
CROSS	JOIN	last_global	lg
ORDER	BY	status,	cl.last_rental;