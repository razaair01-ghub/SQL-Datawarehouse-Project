/*====================================================
This Store procedure loads the data into the bronze schema from external csv files>>truncate sthe tables >> uses bulk insert to load the the data.
--CREATING store procedure for bronze layer
note : this store procedure doesnot accept any parameter or return any values

USAGE example:
Exec bronze.load_bronze;
*/
CREATE or ALTER  PROCEDURE bronze.load_bronze As

BEGIN
	DECLARE @start_time DATETIME, @end_time DAtetime ,  ---To track etl time for optimization and identify the bottleneck
			@batch_start_time DATETIME, @batch_end_time DATETIME;
		BEGIN TRY
					
					SET @batch_start_time = GETDATE();

PRINT '================================================';
PRINT 'Loading bronze layer';
PRINT '================================================';


--===========================================================================================

--             SQL BULK INSERT to load all CSV files into bronze table-----

--===========================================================================================

PRINT '================================================';
PRINT 'Loading CRM TAbles';
PRINT '================================================';

--==== CRM source

			SET @start_time= GETDATE();

			TRUNCATE TABLE bronze.crm_cust_info; --USE TO CLEAN THE TABLE AND AGAIN USE IF DUPLICATE RECORD INSERTED

			BULK INSERT bronze.crm_cust_info   --inserting the data
			FROM 'C:\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
			WITH (
					FIRSTROW = 2,
					FIELDTERMINATOR = ',',
					TABLOCK
			);
			SET @end_time = GETDATE();

		PRINT ' >> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' SECONDS'
		PRINT '---------------------'


			SET @start_time= GETDATE();

			TRUNCATE TABLE bronze.crm_prd_info; --USE TO CLEAN THE TABLE AND AGAIN USE IF DUPLICATE RECORD INSERTED

			BULK INSERT bronze.crm_prd_info
			FROM 'C:\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
			WITH (
					FIRSTROW = 2,
					FIELDTERMINATOR = ',',
					TABLOCK
			);

				SET @end_time = GETDATE();

		PRINT ' >> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' SECONDS'
		PRINT '---------------------'


		SET @start_time= GETDATE();

			TRUNCATE TABLE bronze.crm_sales_details; --USE TO CLEAN THE TABLE AND AGAIN USE IF DUPLICATE RECORD INSERTED

			BULK INSERT bronze.crm_sales_details
			FROM 'C:\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
			WITH (
					FIRSTROW = 2,
					FIELDTERMINATOR = ',',
					TABLOCK
			);

			SET @end_time = GETDATE();

		PRINT ' >> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' SECONDS'
		PRINT '---------------------'

PRINT '================================================';
PRINT 'Loading ERP tables';
PRINT '================================================';
			--===ERP source

			SET @start_time= GETDATE();

			TRUNCATE TABLE bronze.erp_cust_az12; --USE TO CLEAN THE TABLE AND AGAIN USE IF DUPLICATE RECORD INSERTED

			BULK INSERT bronze.erp_cust_az12
			FROM 'C:\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
			WITH (
					FIRSTROW = 2,
					FIELDTERMINATOR = ',',
					TABLOCK
			);

			SET @end_time = GETDATE();

		PRINT ' >> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' SECONDS'
		PRINT '---------------------'


			SET @start_time= GETDATE();


			TRUNCATE TABLE bronze.erp_loc_a101; --USE TO CLEAN THE TABLE AND AGAIN USE IF DUPLICATE RECORD INSERTED

			BULK INSERT bronze.erp_loc_a101
			FROM 'C:\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
			WITH (
					FIRSTROW = 2,
					FIELDTERMINATOR = ',',
					TABLOCK
			);


			SET @end_time = GETDATE();

		PRINT ' >> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' SECONDS'
		PRINT '---------------------'


			
			SET @start_time= GETDATE();

			TRUNCATE TABLE bronze.erp_px_cat_g1v2; --USE TO CLEAN THE TABLE AND AGAIN USE IF DUPLICATE RECORD INSERTED

			BULK INSERT bronze.erp_px_cat_g1v2
			FROM 'C:\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
			WITH (
					FIRSTROW = 2,
					FIELDTERMINATOR = ',',
					TABLOCK
			);

			
			SET @end_time = GETDATE();

		PRINT ' >> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + ' SECONDS'
		PRINT '---------------------'


		SET @batch_end_time = GETDATE();
		PRINT'==============================='
		PRINT 'LOADING BRONZE LAYER is completed';
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



EXec bronze.load_bronze
