SELECT * FROM order_detail;
SELECT * FROM customer_detail;
SELECT * FROM payment_detail;
SELECT * FROM sku_detail;

-- Cek Missing Data order_detail
SELECT 
	* 
FROM 
	order_detail
WHERE
	id IS NULL OR
	customer_id IS NULL OR
	order_date IS NULL OR
	sku_id IS NULL OR
	price IS NULL OR
	qty_ordered IS NULL OR
	before_discount IS NULL OR
	discount_amount IS NULL OR
	after_discount IS NULL OR
	is_gross IS NULL OR
	is_valid IS NULL OR
	is_net IS NULL OR
	payment_id IS NULL;

--Cek Missing Data customer_detail
SELECT
	*
FROM
	customer_detail
WHERE
	id IS NULL OR
	registered_date IS NULL;

--Cek Missing Data payment_detail
SELECT
	*
FROM
	payment_detail
WHERE
	id IS NULL OR
	payment_method IS NULL;

--Cek Missing Detail sku_detail
SELECT
	*
FROM
	sku_detail
WHERE
	id IS NULL OR
	sku_name IS NULL OR
	base_price IS NULL OR
	cogs IS NULL OR
	category IS NULL;

/* No.1 Selama transaksi yang terjadi selama 2021, 
pada bulan apa total nilai transaksi (after_discount) paling besar? 
Gunakan is_valid = 1 untuk memfilter data transaksi. */
SELECT
	TO_CHAR(order_date, 'Month') AS month_2021, 
	ROUND(SUM(after_discount)) AS total_revenue
FROM
	order_detail
WHERE
	is_valid =1 AND
	order_date BETWEEN '2021-01-01' AND '2021-12-31'
GROUP BY
  	month_2021
ORDER BY
  	total_revenue DESC;

/* No.2 Selama transaksi yang terjadi selama 2021, pada bulan apa total jumlah pelanggan (unique), 
total order (unique) dan total jumlah kuantitas produk paling banyak? 
Gunakan is_valid = 1 untuk memfilter data transaksi. */
SELECT
  	TO_CHAR(order_date, 'Month') AS month_2021,
  	COUNT(DISTINCT customer_id) AS total_customer,
  	COUNT(DISTINCT id) AS total_order,
  	SUM(qty_ordered) AS total_qty
FROM
  	order_detail
WHERE
  	is_valid =1 AND
  	order_date BETWEEN '2021-01-01' AND '2021-12-31'
GROUP BY
  	1
ORDER BY
  	2 DESC;

/* No.3 Selama transaksi yang terjadi selama 2022, 
kategori apa yang menghasilkan nilai transaksi paling besar? 
Gunakan is_valid = 1 untuk memfilter data transaksi. */
SELECT 
  	sku.category,
  	ROUND(SUM(ord.after_discount)) AS total_revenue
FROM
  	order_detail AS ord
LEFT JOIN
  	sku_detail AS sku
  	ON ord.sku_id = sku.id
WHERE
  	order_date BETWEEN '2021-01-01' AND '2021-12-31' AND
  	is_valid = 1
GROUP BY
  	1
ORDER BY
  	2 DESC;

/* No.4 Bandingkan nilai transaksi dari masing-masing kategori pada tahun 2021 dengan 2022. 
Sebutkan kategori apa saja yang mengalami peningkatan 
dan kategori apa yang mengalami penurunan nilai transaksi dari tahun 2021 ke 2022. 
Gunakan is_valid = 1 untuk memfilter data transaksi. */
WITH tab_revenue AS (
SELECT 
  	EXTRACT('year' FROM order_date) AS year_order,
  	sku.category,
  	ROUND(SUM(ord.after_discount)) AS total_revenue
FROM
  	order_detail AS ord
LEFT JOIN
  	sku_detail AS sku
  	ON ord.sku_id = sku.id
WHERE
  	EXTRACT('year' FROM order_date) IN (2021, 2022) AND
  	is_valid = 1
GROUP BY
  	sku.category, 
  	EXTRACT('year' FROM order_date)
ORDER BY
  	total_revenue DESC
)
SELECT
  	*, 
  	(year_2022 - year_2021) AS different_revenue
FROM
  	(
  	SELECT
    		category,
    		SUM(CASE WHEN (year_order = 2021) THEN total_revenue 
        	ELSE NULL 
        	END) AS year_2021,
    		SUM(CASE WHEN (year_order = 2022) THEN total_revenue 
        	ELSE NULL 
        	END) AS year_2022
  	FROM
    		tab_revenue
  	GROUP BY
    		category
	) AS pivot
ORDER BY
  	different_revenue DESC;

/* No.5 Tampilkan Top 10 sku_name (beserta kategorinya) berdasarkan nilai transaksi 
yang terjadi selama tahun 2022. Tampilkan juga total jumlah pelanggan (unique), 
total order (unique) dan total jumlah kuantitas. 
Gunakan is_valid = 1 untuk memfilter data transaksi. */
SELECT 
  	sku.sku_name,
  	sku.category,
  	ROUND(SUM(ord.after_discount)) AS total_revenue,
  	COUNT(DISTINCT ord.customer_id) AS total_customer,
  	COUNT(DISTINCT ord.id) AS total_order,
  	SUM(ord.qty_ordered) AS total_qty
FROM
  	order_detail AS ord
LEFT JOIN
  	(
  	SELECT
    		id,
    		sku_name,
    		category
  	FROM
    		sku_detail
  	) AS sku
  	ON ord.sku_id = sku.id
WHERE
  	is_valid = 1 AND
  	date_part('Year', order_date) = 2022
GROUP BY
  	sku.category,
  	sku.sku_name
ORDER BY
  	total_revenue DESC
LIMIT 10;

/* No.6 Tampilkan top 5 metode pembayaran yang paling populer digunakan selama 2022 
(berdasarkan total unique order). 
Gunakan is_valid = 1 untuk memfilter data transaksi. */
SELECT 
  	pay.payment_method,
  	COUNT(DISTINCT ord.id) AS total_order
FROM
  	order_detail AS ord
LEFT JOIN
  	payment_detail AS pay
  	ON ord.payment_id = pay.id
WHERE
  	order_date BETWEEN '2022-01-01' AND '2022-12-31' AND
  	is_valid = 1
GROUP BY
  	pay.payment_method
ORDER BY
  	total_order DESC
LIMIT 5;

/* No.7 Urutkan dari ke-5 produk ini berdasarkan nilai transaksinya. 
	a. Samsung
	b. Apple
	c. Sony
	d. Huawei
	e. Lenovo
Gunakan is_valid = 1 untuk memfilter data transaksi. */
WITH tab_brand AS (
SELECT
  	id,
  	(CASE 
     		WHEN LOWER(sku_name) LIKE '%samsung%' THEN 'Samsung'
     		WHEN LOWER(sku_name) LIKE '%apple%' OR LOWER(sku_name) LIKE '%iphone%' THEN 'Apple'
     		WHEN LOWER(sku_name) LIKE '%sony%' THEN 'Sony'
     		WHEN LOWER(sku_name) LIKE '%huawei%' THEN 'Huawei'
     		WHEN LOWER(sku_name) LIKE '%lenovo%' THEN 'Lenovo'
  	END) AS brand
FROM 
  	sku_detail
)
SELECT 
  	sku.brand,
  	ROUND(SUM(ord.after_discount)) AS total_revenue
FROM
  	order_detail AS ord
LEFT JOIN
  	tab_brand AS sku
  	ON ord.sku_id = sku.id
WHERE
  	is_valid = 1 AND
  	brand IS NOT NULL
GROUP BY
  	sku.brand
ORDER BY
  	total_revenue DESC;

/* No.8 Seperti pertanyaan no. 4, 
buatlah perbandingan dari nilai profit tahun 2021 dan 2022 pada tiap kategori. 
Kemudian buatlah selisih % perbedaan profit antara 2021 dengan 2022 
(profit = after_discount - (cogs*qty_ordered))
Gunakan is_valid = 1 untuk memfilter data transaksi. */
WITH tab_profit AS (
SELECT 
  	EXTRACT('Year' FROM order_date) AS year_order,
  	sku.category,
  	SUM(ord.after_discount - (sku.cogs * ord.qty_ordered)) AS total_profit
FROM
  	order_detail AS ord
LEFT JOIN
  	sku_detail AS sku
  	ON ord.sku_id = sku.id
WHERE
  	order_date BETWEEN '2021-01-01' AND '2022-12-31' AND
  	is_valid = 1
GROUP BY
  	sku.category, year_order
ORDER BY
  	total_profit DESC
),
year_profit AS (
SELECT
  	category,
  	ROUND(SUM(CASE 
            	WHEN (year_order = 2021) THEN total_profit 
            	ELSE NULL 
            	END)) AS year_2021,
  	ROUND(SUM(CASE 
            	WHEN (year_order = 2022) THEN total_profit 
            	ELSE NULL 
            	END)) AS year_2022
FROM
  	tab_profit
GROUP BY
  	category
)
SELECT
  	*,
  	ROUND(((year_2022 / year_2021) - 1) * 100) AS growth_profit
FROM 
  	year_profit
ORDER BY
  	growth_profit;

/* No.9 Tampilkan top 5 SKU dengan kontribusi profit paling tinggi di tahun 2022 
berdasarkan kategori paling besar pertumbuhan profit dari 2021 ke 2022 (berdasarkan hasil no 8).
Gunakan is_valid = 1 untuk memfilter data transaksi. */
WITH tab_profit AS (
SELECT
  	ord.id,
  	sku.sku_name,
  	ord.after_discount - (sku.cogs * ord.qty_ordered) AS profit
FROM 
  	order_detail AS ord
LEFT JOIN 
  	sku_detail AS sku 
  	ON sku.id = ord.sku_id
WHERE
  	is_valid = 1 AND
  	order_date BETWEEN '2022-01-01' AND '2022-12-31' AND
  	sku.category = 'Women Fashion'
)
SELECT 
  	sku_name,
  	SUM(profit) AS total_profit
FROM 
  	tab_profit
GROUP BY 
  	sku_name
ORDER BY 
  	total_profit DESC
LIMIT 5;

/* No.10 Tampilkan jumlah unique order yang menggunakan top 5 metode pembayaran (soal no 6) 
berdasarkan kategori produk selama tahun 2022.
Gunakan is_valid = 1 untuk memfilter data transaksi. */
SELECT
  	sku.category,
  	COUNT(DISTINCT CASE WHEN pay.payment_method = 'cod' THEN ord.id END) AS cod,
  	COUNT(DISTINCT CASE WHEN pay.payment_method = 'Easypay' THEN ord.id END) AS easypay,
  	COUNT(DISTINCT CASE WHEN pay.payment_method = 'Payaxis' THEN ord.id END) AS payaxis,
  	COUNT(DISTINCT CASE WHEN pay.payment_method = 'customercredit' THEN ord.id END) AS customercredit,
  	COUNT(DISTINCT CASE WHEN pay.payment_method = 'jazzwallet' THEN ord.id END) AS jazzwallet
FROM 
  	order_detail AS ord
LEFT JOIN 
  	payment_detail pay 
  	ON pay.id = ord.payment_id
LEFT JOIN 
  	sku_detail sku 
  	ON sku.id = ord.sku_id
WHERE 
  	is_valid = 1 AND
  	order_date BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
  	sku.category
ORDER BY 
  	cod DESC;
	


