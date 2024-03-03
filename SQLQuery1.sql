--create database sf;
--use sf

--see the table

SELECT TOP 10 *
FROM Salaries
ORDER BY NEWID();



-- Query to retrieve column information including descriptions

SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    COLUMN_DEFAULT,
    IS_NULLABLE,
    COLUMNPROPERTY(object_id(TABLE_SCHEMA + '.' + TABLE_NAME), COLUMN_NAME, 'IsIdentity') AS IS_IDENTITY,
    COLUMN_DESCRIPTION.value AS COLUMN_DESCRIPTION
FROM 
    INFORMATION_SCHEMA.COLUMNS
    OUTER APPLY fn_listextendedproperty('MS_Description', 'SCHEMA', TABLE_SCHEMA, 'TABLE', TABLE_NAME, 'COLUMN', COLUMN_NAME) AS COLUMN_DESCRIPTION
WHERE 
    TABLE_NAME = 'Salaries'  -- Replace with your table name
ORDER BY 
    ORDINAL_POSITION;


--Need to check total shape of the data 


--Rows
select count(*) from Salaries

--Columns
SELECT count(COLUMN_NAME)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Salaries';





--There is a column named 'Notes' with no values, so we need to delete this column. Some columns have missing values, and we will fill these values using the mean or median.

select count(*) from Salaries
where Notes is null


-- Drop a specific column from a table

ALTER TABLE Salaries
DROP COLUMN Notes;


--There is a column where the payable amount mean is negative. We need to verify if this is possible because, 
--according to my understanding, this should not happen.


--I found that only one row has negative values, so I am deleting this particular row. 
--After the row has been deleted, I intend to change the data type of this column to FLOAT


-- first check the newmeric values
select * from(
		select round(cast(TotalPay as float),0)as total,
		case when round(cast(TotalPay as float),0) >0 then 1 else 0 end new_slab
		from Salaries)x
where x.new_slab=0

--- -618 this is the

delete from Salaries
where round(cast(TotalPay as float),0) =-618


--now change the datatype of this col

ALTER TABLE Salaries
ALTER COLUMN TotalPay FLOAT;


--check the mean ,min,max,total for this col

SELECT
    AVG(TotalPay) AS Mean,
	min(TotalPay)as Min_values,
	max(TotalPay)as Max_values,
	sum(TotalPay)as Total_values,
	count(*)as total_count
FROM
    Salaries;

--There is a columns BasePay where have some null and text values so need to clean this dataset

--There are 605 rows with null values. Additionally, some rows are filled with 'Not Provided,' 
--so I have decided to fill these rows with '0'."

select count(*)as toalt from Salaries
where BasePay is null


select BasePay from Salaries
order by BasePay asc

-- updating

UPDATE Salaries
SET BasePay=0
where BasePay ='Not Provided' or BasePay is null 

UPDATE Salaries
SET BasePay=0
where BasePay <0

--Change datatype

ALTER TABLE Salaries
ALTER COLUMN BasePay FLOAT;


--check the mean ,min,max,total for this col

SELECT
    AVG(BasePay) AS Mean,
	min(BasePay)as Min_values,
	max(BasePay)as Max_values,
	sum(BasePay)as Total_values,
	count(*)as total_count
FROM
    Salaries;



--Same problem we have in ['OvertimePay']

select OvertimePay from Salaries
order by OvertimePay asc

--Need to update some row where 'Not Provided' mentioned will replace by '0'

UPDATE Salaries
SET OvertimePay=0
where OvertimePay ='Not Provided'


UPDATE Salaries
SET OvertimePay=0
where OvertimePay<0

--Change the datatype

ALTER TABLE Salaries
ALTER COLUMN OvertimePay FLOAT;

--Check the mean ,Min ,Max , Total for this col

SELECT
    AVG(OvertimePay) AS Mean,
	min(OvertimePay)as Min_values,
	max(OvertimePay)as Max_values,
	sum(OvertimePay)as Total_values,
	count(*)as total_count
FROM
    Salaries;



--In the 'Benefits' column, we have multiple null values, so we need to drop this column.

-- Approximately 24% of the values in the Benefits column are null. I will fill these null values with '0'.

select count(*) from Salaries
where Benefits is null 

--Random Check
select Benefits from Salaries
order by Benefits asc


--Updating

UPDATE Salaries	
SET Benefits=0
where Benefits='Not Provided' or Benefits is null

--update <0 values into 0 

UPDATE Salaries	
SET Benefits=0
where Benefits <0


--Change the datatype
		
ALTER TABLE Salaries
ALTER COLUMN Benefits FLOAT;

--Check the mean ,Min ,Max , Total for this col

SELECT
    AVG(Benefits) AS Mean,
	min(Benefits)as Min_values,
	max(Benefits)as Max_values,
	sum(Benefits)as Total_values,
	count(*)as total_count
FROM
    Salaries;


--74% values are missing in status column

select Status from Salaries
order by Status desc

select Status,count(*)as total_cnt from Salaries
group by Status

--Update the all null values with 0

UPDATE Salaries
SET Status=0
where Status is null


--I will do feature's engineering, will make some columns for analysis

--features
-- TotalPay slab
-- TotalPayBenefits slab
-- TotalpayBenefits - Basepay>0 then 1 else 0 (How many emp getting overpay or benefits)
-- Designation columns (I am categorizing the 'Designation' column by counting the occurrences of each designation. If a designation appears more than 100 times, I will retain that designation; otherwise, I will label it as 'Other')


--First Designation Columns:

ALTER TABLE Salaries
ADD Designation VARCHAR(255);


with main as (
    select lower(jobtitle) as jobtitle
    from salaries
    group by jobtitle
    having count(*) > 100
),
main2 as (
    select id,
           case when lower(jobtitle) in (select lower(jobtitle) from main) then lower(jobtitle) else 'others' end as designation_1
    from salaries
)
update salaries
set designation = main2.designation_1
from main2
where salaries.id = main2.id;


select * from Salaries

--TotalPay slab Features/TotalPayBenefits

--slab
-- 0 to 10000 '0-10k'
-- 10000 to 20000 '10k-20k'
-- 20000 to 50000 '20-50k'
-- 50000 to 100000 '50-1L'
-- >100000 '>=1L'

--create col

--TotalPay
ALTER TABLE Salaries
ADD TotalPay_slab VARCHAR(255);

--TotalPayBenefits

ALTER TABLE Salaries
ADD TotalPayBenefits_slab VARCHAR(255);


With main as(
		select *,

		 case when TotalPay between 0 and 10000 then '0-10k'
			  when TotalPay between 10000  and 20000 then '10k-20K'
			  when TotalPay between 20001  and 50000 then '20K-50k'
			  when TotalPay between 50001  and 100000 then '50K-1L'
			  else 'Above 1L'
		end TotalPay_slab_temp,

		 case when TotalPayBenefits between 0 and 10000 then '0-10k'
			  when TotalPayBenefits between 10000  and 20000 then '10k-20K'
			  when TotalPayBenefits between 20001  and 50000 then '20K-50k'
			  when TotalPayBenefits between 50001  and 100000 then '50K-1L'
			  else 'Above 1L'
		end TotalPayBenefits_temp

		from Salaries)
	UPDATE Salaries
	SET TotalPay_slab=main.TotalPay_slab_temp,
	TotalPayBenefits_slab=main.TotalPayBenefits_temp
	from main
	where main.id=Salaries.id



-- TotalpayBenefits - Basepay>0 then 1 else 0 (How many emp getting overpay or benefits)

--Columns adding

ALTER TABLE Salaries
ADD BasePay_TotalpayBenefits int


--Updating col

with main as(
	select *,
	case when (TotalPayBenefits-BasePay)>=1 then 1 else 0 end  as TotalpayBenefits_temp
	from Salaries)
 UPDATE Salaries
 SET BasePay_TotalpayBenefits=main.TotalpayBenefits_temp
 from main
 where Salaries.id=main.id


select * from Salaries



--l I will create some stored procedure:
--I will create a query where I will pass a variable for 'top 10' or 'top 15,' and the query will return results accordingly
	


-- highest-paying jobs for each year (Job title, designation, total pay slab, total pay amount)


CREATE PROCEDURE top_rows (@top int) 

AS

BEGIN 

with main as(
		select EmployeeName,
			   Designation,
			   TotalPay,
			   Year,
			   TotalPay_slab,
			   ROW_NUMBER()over(partition by Year order by TotalPay desc)as rn

		from Salaries)
	select * from main
	where main.rn<=@top

END



EXEC top_rows 1  --- we can give top 10,1,2 like this number the procedure will return the values as per the given argu.



--Create a stored procedure that retrieves the top 5 highest-paying designation roles for a specified year (use a variable for the year).


CREATE PROCEDURE role_high (@year varchar(255))

AS 
BEGIN 

with main as(
		select Designation,TotalPay,
			   ROW_NUMBER()over(partition by Designation order by TotalPay desc)as rn
		from Salaries
		where Year=@year)
 select * from main
 where main.rn<=5
	

END



EXEC role_high 2012

