

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DAtetime ,  ---To track etl time for optimization and identify the bottleneck
			@batch_start_time DATETIME, @batch_end_time DATETIME;
		BEGIN TRY
					
					SET @batch_start_time = GETDATE();

PRINT '================================================';
PRINT 'Loading  CRM table SILVER layer';
PRINT '================================================';


			--===============================================================

			-- Data Transformation and cleaning and inserting from bronzer to silver

			--==============================================================

			--buliding cleaned data fro silver layer
			SET @start_time= GETDATE();
			
			TRUNcate TABLE silver.crm_cust_info;
			PRINT '>> Inserting Data info : silver.crm_cust_info';
			INSERT INTO silver.crm_cust_info (
										cst_id,
										cst_key,
										cst_firstname,
										cst_lastname,
										cst_marital_status,
										cst_gndr,
										cst_create_date )


			SELECT 
					cst_id,
					cst_key,
					TriM(cst_firstname) cst_firstname,				---removes unwanted spaces
					TriM(cst_lastname) cst_lastname,
					CASE 
						WHEN UPPER(cst_marital_status) ='S' THEN 'Single'				---normalize to readable format or standardize values or map values to meaningful
						WHEN UPPER(cst_marital_status) ='M' THEN 'Married'  
						ELSE 'n/a'
					END cst_marital_status,
					CASE 
						WHEN UPPER(cst_gndr) ='M' THEN 'Male'
						WHEN UPPER(cst_gndr) ='F' THEN 'Female'
						ELSE 'n/a'
					END cst_gndr,
					cst_create_date
				FROM(
					SELect
					*,ROW_NUMBER() OVER(PARTITION BY cst_id Order BY cst_create_date DESC) as Flag_last
					FROM bronze.crm_cust_info)t
					WHERE Flag_last=1 AND cst_id is not null --select the most recent record and remove null value from primary key

				SET @end_time = GETDATE();

		PRINT ' >> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' SECONDS'
		PRINT '---------------------'
				
				
				-----------------------------------------------------------------------------
			-- for prd_info table
			---------------------------------------------------------------------------------------
			SET @start_time= GETDATE();
			
			TRUNcate TABLE silver.crm_prd_info;
			PRINT '>> Inserting Data info : silver.crm_prd_info';
			INSERT INTO silver.crm_prd_info(
							prd_id,
							cat_id,
							prd_key,
							prd_nm,
							prd_cost,
							prd_line,
							prd_start_dt,
							prd_end_dt
							)




			SELECT  prd_id,
		
					REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,      -- EXTRACT cat id ,first 5 substring are category id and replace - with _ to match with cat id in erp_cat table
					SUBSTRING(prd_key,7,Len(prd_key)) AS prd_key,           --extract prd key
					prd_nm,
					ISNULL(prd_cost,0) AS prd_cost,
					CASE														--map product line codes to descriptive values
						WHEN UPPER(TRIM(prd_line)) ='M' THEN 'Mountain'
						WHEN UPPER(TRIM(prd_line)) ='R' THEN 'Road'
						WHEN UPPER(TRIM(prd_line)) ='s' THEN 'other Sales'
						WHEN UPPER(TRIM(prd_line)) ='T' THEN 'Touring'
						ELSE 'n/a'
					END AS prd_line,
					CAST(prd_start_dt AS date) AS prd_start_dt,
					CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE			--data enrichment
					) AS prd_end_dt												--calculate end date as one before the next start date
			FROM bronze.crm_prd_info

			SET @end_time = GETDATE();

			PRINT ' >> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' SECONDS'
			PRINT '---------------------'
				

			--=============================================================================================

			-- for bronze sales table

			--============================================================================================

			
			SET @start_time= GETDATE();

			TRUNcate TABLE silver.crm_sales_details;
			PRINT '>> Inserting Data info : silver.crm_sales_details';
			---inserting the data
			Insert into silver.crm_sales_details (
								sls_ord_num,
								sls_prd_key,
								sls_cust_id,
								sls_order_dt,
								sls_ship_dt,
								sls_due_dt,
								sls_sales,
								sls_quantity,
								sls_price
							)




			SELECT  sls_ord_num,
					sls_prd_key,
					sls_cust_id,
					CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL				--HANDLING INVALID DATE
						 ELSE CAST(CAST(sls_order_dt AS varchar) AS DAte)						--DATA TYPE CASTING
					END AS sls_order_dt,
					CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
						 ELSE CAST(CAST(sls_ship_dt AS varchar) AS DAte) 
					END AS sls_ship_dt,
					CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
						 ELSE CAST(CAST(sls_due_dt AS varchar) AS DAte) 
					END AS sls_due_dt,
					CASE    when sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
							THEN sls_quantity * ABS(sls_price)
							ELSE sls_sales													--RECALCULATING SALES IF ORIGINAL VALUE IS MISSING
					END AS sls_sales,
					sls_quantity,
					CASE	
							WHEN sls_price IS NULL OR sls_price <=0 THEN sls_sales / NullIf(sls_quantity,0)
							Else sls_price
				End as sls_price															--DERIVED PRICE IS ORIGINAL VALUE IS INVALID

			FROM bronze.crm_sales_details

			SET @end_time = GETDATE();

			PRINT ' >> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' SECONDS'
			PRINT '---------------------'
			

			PRINT '================================================';
			PRINT 'Loading ERP Silver tables';
			PRINT '================================================';
			--===ERP source
			--=======================================================================

			--ERP CUST Z TABLE

			--============================================================


			--cleaning and inserting into silver layer
			SET @start_time= GETDATE();

			TRUNcate TABLE silver.erp_cust_az12;
			PRINT '>> Inserting Data info : silver.erp_cust_az12';
			INSERT INTO silver.erp_cust_az12(cid,bdate,gen)
			select 
					CASE 
						 WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4 ,LEN(cid))
						 eLSE cid													--remove 'NAS"-' prefix if present
					eND as cid,
					CAse 
						 WHEN bdate > GETDATE() THEN NULL
						 ELSE bdate													--set future bdate to NULL
					END AS bdate,
					CASe 
						 when UPPER(TRIM(gen))  IN ('F','Female') THEN 'Female'
						 WHEN UPPER(TRIM(gen)) IN ('M','Male') THen 'Male'
						 ELSe 'n/a'
					END as gen														--normalize gender values and handle unknow values
			from bronze.erp_cust_az12

			
			SET @end_time = GETDATE();

			PRINT ' >> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' SECONDS'
			PRINT '---------------------'
			



			--=======================================================================

			--ERP location table

			--============================================================
			SET @start_time= GETDATE();

			TRUNcate TABLE silver.erp_loc_a101;
			PRINT '>> Inserting Data info : silver.erp_loc_a101';
			INSERT INTO silver.erp_loc_a101(cid,cntry)


			SELECT  REPLACE(cid,'-','') cid, ---handle invalid value
					Case 
						WHEN TRIM(cntry) = 'DE' THEN 'Germany'
						WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
						WHEN TRIM(cntry) = '' OR cntry IS NULL Then 'n/a'
						ELSE TRIM(cntry)		--normalize and handle missing value or blank country codes
					END as cntry
			FROM bronze.erp_loc_a101

			
			SET @end_time = GETDATE();

			PRINT ' >> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' SECONDS'
			PRINT '---------------------'

			--=======================================================================

			--ERP prd category table

			--============================================================
			SET @start_time= GETDATE();
			TRUNcate TABLE silver.erp_px_cat_g1v2;
			PRINT '>> Inserting Data info : silver.erp_px_cat_g1v2';
			INSERT INTO silver.erp_px_cat_g1v2(id,cat,subcat,maintenance)
			SELECT id,
					cat,
					subcat,
					maintenance
			FROM bronze.erp_px_cat_g1v2


			
			SET @end_time = GETDATE();

			PRINT ' >> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' SECONDS'
			PRINT '---------------------'


			SET @batch_end_time = GETDATE();
		PRINT'==============================='
		PRINT 'LOADINgG SILVER LAYER is completed';
		PRINT '-Total load duration : ' + CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time ) AS NVARCHAR) + 'SECONDS'
		PRINT'==============================='

	END TRY
		--ERROR HANDLInG
		BEGIN CATCH  


					PRINT'==============================================='
					PRINT' ERROR occured during loaing bronze layer'
					PRINT 'Error Message' + ERROR_MESSAGE();
					PRINT 'Erroe Mesaage' + CAst(ERROR_NUMBER() AS NVARCHAR);
					PRINT 'Erroe Mesaage' + CAst(ERROR_STATE() AS NVARCHAR);
					PRINT'==============================================='
		END CATCH
END



EXEC silver.load_silver
			



			---everything is done 
			---now write syntax truncate  for all the above data table to avoid duplicate insert

			--now will create store procedure same as bronze layer--
