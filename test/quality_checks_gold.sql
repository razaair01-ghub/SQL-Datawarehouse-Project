--==================================================================

--BUILDING gold layer  


---------Dimension Customer+++++++++++

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--checking duplicates in primary key

SELECT cst_id,COUNT(*) FROM(
SELECT 
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	ci.cst_gndr,
	ci.cst_create_date,
	ca.bdate,
	ca.gen,
	la.cntry
	

FROm silver.crm_cust_info ci
left join silver.erp_cust_az12 ca
ON ci.cst_key=ca.cid
LEFT JOIN silver.erp_loc_a101 la
On la.cid=ci.cst_key)t
GROUP BY cst_id
HAVING COUNT(*) >1 ---no duplicates


--Data INTEGRation --there are two Columns of gender in table DIMENSION CUSTOMER


SELECT DISTINCT

	ci.cst_gndr,
	
	ca.gen
	

FROm silver.crm_cust_info ci
left join silver.erp_cust_az12 ca
ON ci.cst_key=ca.cid
LEFT JOIN silver.erp_loc_a101 la
On la.cid=ci.cst_key
ORDER BY 1,2 ---there is null which because of joining table,if sql finds no match null appears

---now ask the expert what is the maste data source,if they say crm we willl take the values for crm gender




SELECT DISTINCT

	ci.cst_gndr,
	
	ca.gen,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
		 ELSE COALESCE(ca.gen,'n/a')
		 END AS new_gen
	

FROm silver.crm_cust_info ci
left join silver.erp_cust_az12 ca
ON ci.cst_key=ca.cid
LEFT JOIN silver.erp_loc_a101 la
On la.cid=ci.cst_key
ORDER BY 1,2 


--now arrange data of gold layer and defined surrogate key using window func.
--now created view

--checking data quanlity of view
SELECT *FROM gold.dim_customers

SELECT DISTINCT gender from gold.dim_customers



-------now for gold for dimension product and checking duplicates
SELECT prd_key,COUNT(*) FROM(
SELECT
		prd_id,
		cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		pc.cat,
		pc.subcat,
		pc.maintenance
FROM silver.crm_prd_info pn
left join silver.erp_px_cat_g1v2 pc
On pc.id=pn.cat_id
WHERE prd_end_dt IS NULL )t
GROUP BY prd_key
HAVING COUNT(*) >1



SElect * FROM gold.dim_products
