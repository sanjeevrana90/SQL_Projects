-- Q1 - 
/*
Write a query to return the email, first name, last name and genre or all Rock Music listeners.
Return your list ordered alphabetacilly by email starting with A
*/

SELECT DISTINCT cus.email, cus.first_name, cus.last_name, gen.name
FROM customer cus
JOIN invoice inv
ON cus.customer_id = inv.customer_id
JOIN invoice_line inv_li
ON inv.invoice_id = inv_li.invoice_id
JOIN track tra
ON inv_li.track_id = tra.track_id
JOIN genre gen
ON tra.genre_id = gen.genre_id
WHERE gen.name = 'Rock'
ORDER BY cus.email ASC

-- Q2
/*
Let's invite the artists who have written the most rock music in our dataset.
Write a query that returns the Artist name and total track count of the top 10 Rock bands
*/

SELECT artist.name, COUNT(artist.name) no_of_songs
from track
JOIN genre
on track.genre_id = genre.genre_id
JOIN album
ON track.album_id = album.album_id
JOIN artist
ON album.artist_id = artist.artist_id
WHERE genre.name = 'Rock'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10

-- Q3 - 
/*
Return all the track names that have a song length longer than the average song length.
Return the Name and miliseconds for each track.
Order by the song length with the longest songs listed first
*/

SELECT name, milliseconds
FROM track 
WHERE milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY 2 DESC

--Q4 - 
/*
Find how much amount spent by each customer on artists?
Write a query to return customer name, artist name and total spent
*/

SELECT TRIM(CONCAT(TRIM(customer.first_name), ' ', TRIM(customer.last_name))) AS cus_name, 
artist.name, 
SUM(invoice_line.unit_price * invoice_line.quantity) AS total_spent
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
JOIN track ON invoice_line.track_id = track.track_id
JOIN album ON track.album_id = album.album_id
JOIN artist ON album.artist_id = artist.artist_id
GROUP BY 1, 2
ORDER BY 2

-- Q5
/*
We want to find out the most popular music genre for each country. We determine 
the most popular genre as the genre with highest amount of purchase. 
Write a query that returns each country along with the top genre.
For countries where the maximum number of purchases is shared return all genre.
*/
WITH highest_selling_by_genre AS (
	SELECT invoice.billing_country, genre.name AS genre,
		   SUM(invoice.total) AS total_sales_by_country,
		   ROW_NUMBER() OVER (PARTITION BY invoice.billing_country ORDER BY SUM(invoice.total) DESC) AS rowno
	FROM invoice
	JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
	JOIN track ON invoice_line.track_id = track.track_id
	JOIN genre ON track.genre_id = genre.genre_id
	GROUP BY 1, 2
	ORDER BY 1, 2 DESC
)
SELECT billing_country, genre
FROM highest_selling_by_genre
WHERE rowno <= 1

-- Q6
/*
Write a query that determines the customer that has spent the most on music for each country.
Write a query that returns the country along with the top customer and how much they spent.
For countries where the top amount spent is shared, provice all customers who spent this amount
*/
WITH RECURSIVE
	customer_with_country AS (
		SELECT customer.customer_id, first_name, last_name, billing_country,
			SUM(total) total_spending
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 2,3 DESC
	),
	customer_max_spending AS (
		SELECT billing_country, MAX(total_spending) max_spending
		FROM customer_with_country
		GROUP BY billing_country
	)	
SELECT cc.billing_country, cc.total_spending, cc.first_name, cc.last_name, cc.total_spending
FROM customer_with_country cc
JOIN customer_max_spending ms
ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.max_spending
ORDER BY 1

-- Method #2
WITH customer_with_country AS (
	SELECT customer.customer_id, first_name, last_name, billing_country,
			SUM(total) total_spending,
			ROW_NUMBER () OVER (PARTITION BY billing_country ORDER BY SUM(total) DESC) rowno
	FROM invoice
	JOIN customer ON customer.customer_id = invoice.customer_id
	GROUP BY 1,2,3,4
	ORDER BY 4, 5 DESC
)
SELECT * 
FROM customer_with_country
WHERE rowno <= 1