select *
from data_cleaning.nashville_housing_data
;

select STR_TO_DATE(saledate,'%M %d,%Y') as date, uniqueid, propertyaddress
from data_cleaning.nashville_housing_data
order by propertyaddress, date
;

-- Finally, a query where the date formatting is working
select *
from data_cleaning.nashville_housing_data
where propertyaddress = '0  40TH AVE N, NASHVILLE'
order by propertyaddress, STR_TO_DATE(saledate,'%M %d,%Y')
;
/*
select *
from data_cleaning.nashville_housing_data
where propertyaddress = '0  40TH AVE N, NASHVILLE'
order by propertyaddress, saledate
;
I made a view to retrieve the date data
select STR_TO_DATE(saledate,'%M %d,%Y') as date
from data_cleaning.nashville_housing_data
order by date
;


select STR_TO_DATE(saledate,'%M %d,%Y') as date, uniqueid, propertyaddress
from data_cleaning.nashville_housing_data
;

select *
from date
;


-- select convert(datetime, '08/10/2001', 103)
-- from data_cleaning.nashville_housing_data
-- ;
SELECT STR_TO_DATE('01,5,2013','%d,%m,%Y');
*/


/*
Cleaning Data in SQL Queries
*/

select *
from data_cleaning.nashville_housing_data
;

-- Variation 1
select *
from data_cleaning.nashville_housing_data
order by propertyaddress, STR_TO_DATE(saledate,'%M %d,%Y')
;

-- Variation 2
select *
from data_cleaning.nashville_housing_data
order by propertyaddress, convert(STR_TO_DATE(saledate,'%M %d,%Y'), date)
;

-- Standardising date format
select saledate, STR_TO_DATE(saledate,'%M %d,%Y') as date, convert(STR_TO_DATE(saledate,'%M %d,%Y'), datetime) as date2
from data_cleaning.nashville_housing_data
;
/* 
Looking at the column date2, it is the date format which I want to continue with. 

I will now update the dataset with this standardised date format
*/
-- Query to check if the update worked as expected
select saledate
from data_cleaning.nashville_housing_data
;

update nashville_housing_data
set saledate = convert(STR_TO_DATE(saledate,'%M %d,%Y'), datetime)
; -- WOO WORKED

-- Populate property address data
select *
from data_cleaning.nashville_housing_data
where propertyaddress = ''
;

select *
from data_cleaning.nashville_housing_data
order by ParcelID
;

/* 
From analysing the data, we can see that each parcelid is reflective of at least one or more propertyaddress
So if there existed a propertyaddress that was empty, we can fill it in based on the parcelid given
*/
-- Error Code: 1582. Incorrect parameter count in the call to native function 'isnull'

-- Run a join on the data itself, essentially duplicating it. Then adding a column with ifnull to see if the tuple is null.
select d1.parcelid, d1.propertyaddress, d2.parcelid, d2.propertyaddress, ifnull(d1.propertyaddress, d2.propertyaddress) as checker -- checker does not work as the data does not include nulls, mysql automatically made them empty cells
from data_cleaning.nashville_housing_data as d1
join data_cleaning.nashville_housing_data as d2 on d2.parcelid= d1.parcelid and d2.uniqueid != d1.uniqueid
where d1.propertyaddress = ''
;

select d1.parcelid, d1.propertyaddress, d2.parcelid, d2.propertyaddress,
case when d1.propertyaddress = '' then d2.propertyaddress
	else 0
    end as checker
from data_cleaning.nashville_housing_data as d1
join data_cleaning.nashville_housing_data as d2 on d2.parcelid= d1.parcelid and d2.uniqueid != d1.uniqueid
where d1.propertyaddress = ''
;

-- Updating the database with the propertyaddresses being filled in when empty
/* 
Using the case control function does not work, it says the 'from' is not valid in this position if I add a semicolon after end, and also expecting EOF ';' when I don't add a semicolon. 
Weird. Need to find a work around this.

27/05/2022 10:32:09pm
Upon further research, I have found out that the multi-table update syntax in MySQL is different from Microsoft SQL Server which requires the tables to be specified with a 'from' and / or 'join' clause.
MySQL implicitly determines which table to update depending on the 'set' clause and what columns are being updated.
*/

update data_cleaning.nashville_housing_data as d1
join data_cleaning.nashville_housing_data as d2 on d2.parcelid= d1.parcelid and d2.uniqueid != d1.uniqueid
set d1.propertyaddress = d2.propertyaddress
where d1.propertyaddress = ''
; -- WORKED WOO, when testing with the query above with the checker column, the output is empty, meaning there are no empty properyaddresses in the database now!

-- Breaking out address into individual columns (address, city, state)
/*
Currently a tuple in the propertyaddress column has the following results:
(Address + City)
*/

select propertyaddress
from data_cleaning.nashville_housing_data
;

-- Query to extract the address and city section of the tuple and split it into separate columns
select propertyaddress, substring_index(propertyaddress, ',', 1) as address, substring_index(propertyaddress, ',', -1) as city
from data_cleaning.nashville_housing_data
;

-- Alter the dataset to include two new columns called propertysplitaddress and propertycity, then update the dataset and insert the tuples into both columns
alter table nashville_housing_data
add propertysplitaddress text,
add propertystate text
; -- WORKED WOO; 23:13:50	alter table nashville_housing_data add propertysplitaddress text, add propertystate text	0 row(s) affected Records: 0  Duplicates: 0  Warnings: 0	0.058 sec

update nashville_housing_data
set 
	propertysplitaddress = substring_index(propertyaddress, ',', 1),
	propertystate = substring_index(propertyaddress, ',', -1)
; -- WORKED WOO; 23:16:05	update nashville_housing_data set   propertysplitaddress = substring_index(propertyaddress, ',', 1),  propertystate = substring_index(propertyaddress, ',', -1)	56465 row(s) affected Rows matched: 56465  Changed: 56465  Warnings: 0	3.440 sec

/* 
27/05/2022 11:42:39pm
Realised I made a mistake, calling the column propertystate instead of propertycity
*/

alter table nashville_housing_data
rename column propertystate to propertycity
;

select propertyaddress, propertysplitaddress, propertystate
from data_cleaning.nashville_housing_data
;

-- Similarly, performing the same events to the owneraddress by splitting it into address, city and state
select owneraddress, substring_index(owneraddress, ',', 1) as address, substring_index(substring_index(owneraddress, ',', 2),',',-1) as city, substring_index(owneraddress, ',', -1) as state
from data_cleaning.nashville_housing_data
;

-- Alter the dataset to include three new columns called
alter table nashville_housing_data
add ownersplitaddress text,
add ownercity text,
add ownerstate text
; -- WORKED WOO; 23:45:03	alter table nashville_housing_data add ownersplitaddress text, add ownercity text, add ownerstate text	0 row(s) affected Records: 0  Duplicates: 0  Warnings: 0	0.017 sec

update nashville_housing_data
set 
	ownersplitaddress = substring_index(owneraddress, ',', 1),
	ownercity = substring_index(substring_index(owneraddress, ',', 2),',',-1),
    ownerstate = substring_index(owneraddress, ',', -1)
; -- WORKED WOO; 23:46:07	update nashville_housing_data set   ownersplitaddress = substring_index(owneraddress, ',', 1),  ownercity = substring_index(substring_index(owneraddress, ',', 2),',',-1),     ownerstate = substring_index(owneraddress, ',', -1)	56465 row(s) affected Rows matched: 56465  Changed: 56465  Warnings: 0	2.366 sec

-- Changing the Y / N in soldasvacant to Yes and No
select distinct soldasvacant, count(soldasvacant) as counter
from data_cleaning.nashville_housing_data
group by soldasvacant
;

select soldasvacant,
case 
	when soldasvacant = 'Y' then 'Yes'
    when soldasvacant = 'N' then 'No'
    else soldasvacant
    end
from data_cleaning.nashville_housing_data
order by soldasvacant
;

update nashville_housing_data
set soldasvacant = 
case 
	when soldasvacant = 'Y' then 'Yes'
    when soldasvacant = 'N' then 'No'
    else soldasvacant
    end
; -- WORKED WOO; 11:44:12	update nashville_housing_data set soldasvacant =  case   when soldasvacant = 'Y' then 'Yes'     when soldasvacant = 'N' then 'No'     else soldasvacant     end	451 row(s) affected Rows matched: 56465  Changed: 451  Warnings: 0	0.196 sec

-- Removing duplicates
select *
from data_cleaning.nashville_housing_data
;

-- From this query, all tuples with row_num = 2, is a duplicate
with duplicatecheck as (
select *,
row_number() over (partition by
	parcelid,
    propertyaddress,
    saleprice,
    saledate,
    legalreference
    order by parcelid
    )
    as row_num
from data_cleaning.nashville_housing_data
-- where row_num > 1 -- Cannot use row_num > 1 since it is a function; Error Code: 1054. Unknown column 'row_num' in 'where clause'
-- order by row_num desc
)
select *
from duplicatecheck
where row_num > 1
;

-- Executing the removing of duplicates; 11:56:39	with duplicatecheck as ( select *, row_number() over (partition by  parcelid,     propertyaddress,     saleprice,     saledate,     legalreference     order by parcelid     )     as row_num from data_cleaning.nashville_housing_data -- where row_num > 1 -- Cannot use row_num > 1 since it is a function; Error Code: 1054. Unknown column 'row_num' in 'where clause' -- order by row_num desc ) delete from duplicatecheck where row_num > 1	Error Code: 1288. The target table duplicatecheck of the DELETE is not updatable	0.0025 sec
with duplicatecheck as (
select *,
row_number() over (partition by
	parcelid,
    propertyaddress,
    saleprice,
    saledate,
    legalreference
    order by parcelid
    )
    as row_num
from data_cleaning.nashville_housing_data
-- where row_num > 1 -- Cannot use row_num > 1 since it is a function; Error Code: 1054. Unknown column 'row_num' in 'where clause'
-- order by row_num desc
)
delete
from duplicatecheck
where row_num > 1
; -- Error Code: 1288. The target table duplicatecheck of the DELETE is not updatable

alter table nashville_housing_data
add duplicate_row_num int
; -- WORKED WOO; 12:02:16	alter table nashville_housing_data add duplicate_row_num int	0 row(s) affected Records: 0  Duplicates: 0  Warnings: 0	0.101 sec

update nashville_housing_data
set duplicate_row_num = row_number() over (
partition by
	parcelid,
    propertyaddress,
    saleprice,
    saledate,
    legalreference
    order by parcelid
)
; -- DIDN'T WORK; Error Code: 3593. You cannot use the window function 'row_number' in this context.'

with duplicatecheck as (
select
row_number() over (partition by
	parcelid,
    propertyaddress,
    saleprice,
    saledate,
    legalreference
    order by parcelid
    )
    as row_num
from data_cleaning.nashville_housing_data
)
update data_cleaning.nashville_housing_data as d
join duplicatecheck as dc
set d.duplicate_row_num = dc.row_num
; -- DIDN'T WORK; Says lost connection, I assume it takes too long, need to find alternative method to do this; Error Code: 2013. Lost connection to MySQL server during query

select * 
from duplicates
;

-- Trying to use a view to join with the original database
update data_cleaning.nashville_housing_data as d
join duplicates as ds
set d.duplicate_row_num = ds.row_num
; -- DIDN'T WORK; " 					"

-- Using select into to try add the data into the new duplicate_row_num column
with duplicatecheck as (
select parcelid,
row_number() over (partition by
	parcelid,
    propertyaddress,
    saleprice,
    saledate,
    legalreference
    order by parcelid
    )
    as row_num
from data_cleaning.nashville_housing_data
)
select row_num
from duplicatecheck
order by parcelid
; -- DIDN'T WORK; 16:40:34	with duplicatecheck as ( select row_number() over (partition by  parcelid,     propertyaddress,     saleprice,     saledate,     legalreference     order by parcelid     )     as row_num into duplicate_row_num from data_cleaning.nashville_housing_data ) select * from duplicatecheck	Error Code: 1327. Undeclared variable: duplicate_row_num	0.0042 sec
-- Error Code: 1172. Result consisted of more than one row

-- Thought about using a cursor, but apparently cursors in MySQL are read-only, meaning it cannot update data in a table
with duplicatecheck as (
select parcelid,
row_number() over (partition by
	parcelid,
    propertyaddress,
    saledate
    order by parcelid
    )
    as row_num
from data_cleaning.nashville_housing_data
)
update nashville_housing_data as d
join duplicatecheck as dc on dc.parcelid = d.parcelid
set d.duplicate_row_num = dc.row_num
-- where d.duplicate_row_num != dc.row_num
; -- Error Code: 1205. Lock wait timeout exceeded; try restarting transaction
-- 0 row(s) affected Rows matched: 56465  Changed: 0  Warnings: 0
with duplicatecheck as (
select parcelid as tempparcelid,
row_number() over (partition by
	parcelid,
    propertyaddress,
    saleprice,
    saledate,
    legalreference
    order by parcelid
    )
    as row_num
from data_cleaning.nashville_housing_data
),
duplicateerror as (
select *
from data_cleaning.nashville_housing_data as d
join duplicatecheck as dc on dc.tempparcelid = d.parcelid
where d.duplicate_row_num != dc.row_num
)
select *
from duplicateerror
where duplicate_row_num != row_num
; -- 17:40:59	with duplicatecheck as ( select parcelid, row_number() over (partition by  parcelid,     propertyaddress,     saleprice,     saledate,     legalreference     order by parcelid     )     as row_num from data_cleaning.nashville_housing_data ), duplicateerror as ( select * from data_cleaning.nashville_housing_data as d join duplicatecheck as dc on dc.parcelid = d.parcelid where d.duplicate_row_num != dc.row_num ) select * from duplicateerror	Error Code: 1060. Duplicate column name 'parcelid'	0.00042 sec
-- Error Code: 1288. The target table duplicateerror of the DELETE is not updatable

-- Restarting this entire thing
alter table nashville_housing_data
drop column duplicate_row_num
;

select *
from (
		select parcelid, row_number() over (partition by
			parcelid,
			propertyaddress,
			saledate
			order by parcelid) as row_num
		from data_cleaning.nashville_housing_data
    ) as t
where row_num = 1
; -- 19:42:15	select * from (   select id, row_number() over (partition by    parcelid,    propertyaddress,    saledate    order by parcelid)    from data_cleaning.nashville_housing_data     )	Error Code: 1248. Every derived table must have its own alias	0.00048 sec

delete
from nashville_housing_data
where parcelid in (
	select parcelid
    from (select parcelid, row_number() over (partition by
			parcelid,
			propertyaddress,
			saledate
			order by parcelid) as row_num
		from data_cleaning.nashville_housing_data
        ) as t
	where row_num > 1
)
;


select *
from duplicate2
where row_num > 1
;

select parcelid, count(*) as counter
from data_cleaning.nashville_housing_data
group by parcelid
order by counter desc
;

-- Delete unused columns
alter table nashville_housing_data
drop column owneraddress,
drop column propertyaddress,
drop column taxdistrict
;

select * 
from data_cleaning.nashville_housing_data
;