/*

CLEANING DATA USING SQL QUERIES

USED: CREATE TABLE, DATA CONVERSION, UPDATE/ALTER TABLE, ADD/ALTER/DELETE COLUMNS, 
	  COALESCE(), SELF JOINS, SUBSTRING(), POSITION(), SPLIT_PART(), CASE STATEMENTS, 
	  CTE, PARTITION BY
	  

*/

--Create Table And Import CSV
CREATE TABLE nashville(
  uniqueid SERIAL, 
  parcelid VARCHAR(50), 
  landuse VARCHAR(255), 
  propertyaddress VARCHAR(255), 
  saledate DATE, 
  saleprice INTEGER, 
  legalreference VARCHAR(50), 
  soldasvacant TEXT, 
  ownername VARCHAR(255), 
  owneraddress VARCHAR(255), 
  acreage DECIMAL(10, 2), 
  taxdistrict VARCHAR(255), 
  landvalue INTEGER, 
  buildingvalue INTEGER, 
  totalvalue INTEGER, 
  yearbuilt INTEGER, 
  bedrooms INTEGER, 
  fullbath INTEGER, 
  halfbath INTEGER
);



--Standardize Date Format
SELECT 
  saledate 
FROM 
  nashville;
  
ALTER TABLE 
  nashville ALTER COLUMN saledate TYPE date;



--Populate Null Property Address Data
SELECT 
  a.parcelid, 
  a.propertyaddress, 
  b.parcelid, 
  b.propertyaddress, 
  COALESCE(
    a.propertyaddress, b.propertyaddress
  ) 
FROM 
  nashville a 
  JOIN nashville b ON a.parcelid = b.parcelid 
  AND a.uniqueid <> b.uniqueid 
WHERE 
  a.propertyaddress ISNULL;
  
UPDATE 
  nashville a 
SET 
  propertyaddress = COALESCE(
    a.propertyaddress, b.propertyaddress
  ) 
FROM 
  nashville b 
WHERE 
  a.parcelid = b.parcelid 
  AND a.uniqueid <> b.uniqueid;
	
	

--Splitting Property Address Into Separate Columns (Address, City)
SELECT 
  SUBSTRING(
    propertyaddress FOR POSITION(',' IN propertyaddress)-1
  ) AS prop_address, 
  SUBSTRING(
    propertyaddress 
    FROM 
      POSITION(',' IN propertyaddress)+ 1
  ) AS prop_city 
FROM 
  nashville;
  
ALTER TABLE 
  nashville 
ADD 
  COLUMN prop_address VARCHAR(255), 
ADD 
  COLUMN prop_city VARCHAR(50);
UPDATE 
  nashville 
SET 
  prop_address = SUBSTRING(
    propertyaddress FOR POSITION(',' IN propertyaddress)-1
  );
  
UPDATE 
  nashville 
SET 
  prop_city = SUBSTRING(
    propertyaddress 
    FROM 
      POSITION(',' IN propertyaddress)+ 1
  );



--Splitting Owner Address Into Separate Columns (Address, City, State)
SELECT 
  owneraddress 
FROM 
  nashville;
  
SELECT 
  SPLIT_PART(owneraddress, ',', 1) AS own_address, 
  SPLIT_PART(owneraddress, ',', 2) AS own_city, 
  SPLIT_PART(owneraddress, ',', 3) AS own_state 
FROM 
  nashville 
  
ALTER TABLE 
  nashville 
ADD 
  COLUMN own_address VARCHAR(255), 
ADD 
  COLUMN own_city VARCHAR(50), 
ADD 
  COLUMN own_state VARCHAR(5);
  
UPDATE 
  nashville 
SET 
  own_address = SPLIT_PART(owneraddress, ',', 1);
  
UPDATE 
  nashville 
SET 
  own_city = SPLIT_PART(owneraddress, ',', 2);
  
UPDATE 
  nashville 
SET 
  own_state = SPLIT_PART(owneraddress, ',', 3);



--Change 'true' And 'false' To Yes And No In "soldasvacant"
ALTER TABLE 
  nashville ALTER COLUMN soldasvacant TYPE TEXT;
  
SELECT 
  soldasvacant, 
  CASE WHEN soldasvacant = 'Y' THEN 'Yes' WHEN soldasvacant = 'N' THEN 'No' ELSE soldasvacant END 
FROM 
  nashville 
  
UPDATE 
  nashville 
SET 
  soldasvacant = CASE WHEN soldasvacant = 'Y' THEN 'Yes' WHEN soldasvacant = 'N' THEN 'No' ELSE soldasvacant END



--Removing Duplicate Values
WITH row_num_cte AS(
  SELECT 
    uniqueid, 
    ROW_NUMBER() OVER (
      PARTITION BY parcelid, 
      propertyaddress, 
      saleprice, 
      saledate, 
      legalreference 
      ORDER BY 
        uniqueid
    ) AS row_num 
  FROM 
    nashville
) 
DELETE FROM 
  nashville 
WHERE 
  uniqueid IN (
    SELECT 
      uniqueid 
    from 
      row_num_cte 
    WHERE 
      row_num > 1
  );



--Removing Unused Columns
ALTER TABLE 
  nashville 
DROP 
  COLUMN owneraddress, 
DROP 
  COLUMN propertyaddress, 
DROP 
  COLUMN taxdistrict;
  
ALTER TABLE 
  nashville 
DROP 
  COLUMN saledate;
