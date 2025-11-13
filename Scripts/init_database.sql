/*
==========================================
Creating Database and Schemas
==========================================

Script--

Creates a new database named 'DataWarehouse' after checking if it already exist then DROP and created.
Additionally set ups three schemas within the data base : 'bronze' ,'silver', 'gold'.




Warning:
*/


Use master 
Go



CREATE DATABASE DataWarehouse

USE DataWarehouse;

GO
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;



