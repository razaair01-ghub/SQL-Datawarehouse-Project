--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--cCreating view that is gold layer : dim Cutomers

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE VIEW gold.dim_customers AS
SELECT 
	ROW_NUMBER() OVER(ORDER BY cst_id) AS customer_key,  --suurogate keys to easily connect facts with dimension
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE 
			WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
		    ELSE COALESCE(ca.gen,'n/a')
    END AS gender,
	ca.bdate AS birth_date,
	ci.cst_create_date As create_date
FROm silver.crm_cust_info ci
left join silver.erp_cust_az12 ca
ON ci.cst_key=ca.cid
LEFT JOIN silver.erp_loc_a101 la
On la.cid=ci.cst_key





--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--cCreating view that is gold layer : dim Cutomers

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE VIEW gold.dim_products AS
SELECT
		ROW_NUMBER() OVER(ORDER BY prd_start_dt,prd_key) As product_key,
		pn.prd_id AS product_id,
		
		pn.prd_key AS product_number,
		pn.prd_nm AS product_name,
		pn.cat_id AS category_id,
		pc.cat AS category_name,
		pc.subcat As subcategory,
		pc.maintenance ,
		prd_cost As cost,
		pn.prd_line As product_line,
		pn.prd_start_dt As start_date	
FROM silver.crm_prd_info pn
left join silver.erp_px_cat_g1v2 pc
On pc.id=pn.cat_id
WHERE prd_end_dt IS NULL  ---Filter out historical data




--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--cCreating view that is gold layer : FAct Sales

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE VIEW gold.fact_sales AS


SELECT		
		sls_ord_num As order_number,
		pr.product_key,
		c.customer_key,
		sls_order_dt As order_date,
		sls_ship_dt As shipping_date,
		sls_due_dt As due_date,
		sls_sales As sales,
		sls_quantity As quantity,
		sls_price As price

FROM silver.crm_sales_details s
LEFT JOIN gold.dim_products pr
On sls_prd_key=pr.product_number
LEFT JOIN gold.dim_customers c
ON c.customer_id=sls_cust_id



--foreign key integrity check(dimension)

SELECT * FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c
ON c.customer_key=s.customer_key
LEFT JOIN gold.dim_products pr
On pr.product_key=s.product_key
WHERE c.customer_key IS NULL or pr.product_key IS NULl
