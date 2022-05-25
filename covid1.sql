-- Selecting the entire table
select * 
from covid.covid_deaths
;

select distinct location
from covid.covid_deaths
;

select distinct continent
from covid.covid_deaths
;
-- # total cases, new cases, total deaths by location
select location, date, total_cases, new_cases, total_deaths
from covid.covid_deaths
order by 1, 2
;

-- Calculating the death rate (total cases / total deaths) everyday for each country
select location, date, (total_deaths / total_cases) * 100 as death_rate
from covid.covid_deaths
;

-- Using a view to calculate the death rate and specify to a country
select *
from death_rate
where location = 'Australia'
;

-- Ordering by highest to lowest death rates for each country
select location, date, total_deaths, total_cases, (total_deaths / total_cases) * 100 as death_rate
from covid.covid_deaths
order by death_rate desc
;

/* 
Found an interesting result, Cayman Islands during March of 2022, specifically on the 17th and 18th, experienced a 100% death rate?
Looking into it deeper, I showed the results of the total_deaths and total_cases to see what the scale of the death rate is,
and evidently, it was to a minor scale as there was only a single case and that individual passed away the same day. 

I wanted to look into why this happened, whether it was the individual was in serious condition with no hospitality, or that they had an existing weak immunity which could not be saved.

Looking into the Cayman Islands quality of life and health service quality, the Cayman Islands has a GDP per capity of $91,392, the highest standard of living in the Caribbean. 

We can predict that the individual must have already existing health issues which would have further weakened his body.
*/

-- Looking at total cases vs population per country
select location, date, total_cases, population, (total_cases / population)*100 as contract_rate
from covid.covid_deaths
order by location asc
;

-- Looking at which country has the highest infection rates
select location, population, max(total_cases) as highest_infections, max((total_cases / population)*100) as contract_rate
from covid.covid_deaths
group by location, population
order by contract_rate desc
;

-- Looking at each country's highest death count per population
select location, max(cast(total_deaths as decimal)) as deaths
from covid.covid_deaths
where continent != ''
group by location
order by deaths desc
;

-- Looking at each continent's death counts
select location, max(cast(total_deaths as decimal)) as deaths
from covid.covid_deaths
where continent = ''
group by location
order by deaths desc
;

-- Looking at new cases and deaths per country
select location, sum(new_cases) as total_new_cases, sum(new_deaths) as total_new_deaths, max(total_cases) as total_cases, max(total_deaths) as total_deaths
from covid.covid_deaths
group by location
order by total_new_cases desc
;

/*
Interesting find, the sum of new cases and deaths is not equal to the max amount of total cases and deaths, which does not make sense as 
the max amount of total cases and deaths should equal to the sum of new cases and deaths.

I have decided to deep dive and analyse a small country to be able to understand why the results being shown are as given.

I looked into Kiribiti and why the sum of new cases and deaths were inconsistent with the max total cases and deaths.

Firstly, I wrote a query to get the data for new && total cases and deaths and exported the results into a csv. I then used sum functions to confirm what the correct result should be.
I then ran my own sum functions as well as comparison functions to see if there were any errors in the data. I found that in on 22/3/2022 there was an inconsistency between the sum of new cases
and the total cases. The sum output 3061 while the max was only 3057. The row for the total_cases on the 22/3/2022 is therefore incorrect and not updated with the correct total_cases number. 
This difference of 4 expresses why the end results were 4 apart (3097 vs 3093).

I know realised I need to clean the data because I did not realise this issue existed beforehand. 
*/

select location, date, new_cases, new_deaths, total_cases, total_deaths
from covid.covid_deaths
where location = 'Kiribati'
;

select location, sum(cast(new_cases as decimal)) as sum_new_cases, sum(new_deaths) as sum_new_deaths, max(cast(total_cases as decimal)) as max_total_cases, max(cast(total_deaths as decimal)) as max_total_deaths
from covid.covid_deaths
where location = 'Kiribati'
group by location
;

-- Looking at the covid_vaccinations table
select * 
from covid.covid_vaccinations
;
/* 
From looking at what data the table holds, we can identify that the date is a primary key. This is based off following the functional dependency theory
which depicts that every tuple in the date column is unique, meaning it has functional dependency on every other column in the table.

Furthermore, the location is also a primary key as the tuple for each date is reflective of the same location with different values in every other column.
Thus, if the schema was of R = A,B,C,D,E,F,G with A being location and B being date, C being new_cases, d being new_deaths etc.

An instance r(R) of the schema R would have a collection of dependencies F = {AB -> CDEFG}, key(R) = AB
This schema is currently in Boyce-Codd Normal Form (BCNF) since the left hand side is a whole key.
*/



-- Joining both tables, covid_deaths and covid_vaccinations and using partition by to run analysis on sum of new_vaccinations per country over the entire period
select d.continent, d.location, d.date, d.new_cases, d.new_deaths, v.new_tests, v.new_vaccinations, sum(cast(v.new_vaccinations as decimal)) over (partition by d.location order by d.location, d.date) as total_vaccinations
from covid.covid_deaths as d
join covid.covid_vaccinations as v on d.date = v.date and d.location = v.location
-- where d.continent != ''
order by d.location, d.date 
limit 100
;

select d.continent, d.location, d.date, d.new_cases, d.new_deaths, v.new_tests, v.new_vaccinations
from covid.covid_deaths as d
join covid.covid_vaccinations as v on d.location = v.location and d.date = v.date
order by d.location, d.date
limit 10
;
/*
I have run into a problem where I cannot order by location and date as the date field will show complerely random data of dates from 1/1/2021, 1/1/2022, 1/10/2020, 1/10/2021 etc.
It currently makes no sense to me and I am going to deep dive to see what is causing this issue. My initial response is that the datatype of the dates in both tables are not 
the same, which is causing an issue when joining.

Upon analysing, the data will also need to be cleaned and edit, specifically the date needs to follow the format YYYY/MM/DD instead of DD/MM/YYYY as MySQL cannot convert the date
to datatype date or datetime. I believe this change will fix the order by errors.

25/05/2022 11:08:13pm
I have found the solution!!!!!!!!

I was using STR_TO_DATE() incorrectly. The second parameter is meant to reflect what the string is formatted in. 
For example, if the query was select str_to_date('08-10-2001', X)
X should be equal to '%d-%m-%Y' => str_to_date('08/10/2001', '%d-%m-%Y')

If the query was select str_to_date('October 8, 2001', X)
X should be equal to '%M %d,%Y' => str_to_date('October 8, 2001', '%M %d,%Y')

The issue was that I interpreted the second parameter in the str_to_date() function to be the format I wanted the output to be in. Upon further research, that is what the date_format() function is for!
*/

select location, date_format(date, '%d/%m/%Y'), new_vaccinations
from covid.covid_vaccinations
order by location, date -- does not work since the date is currently text datatype
;

select location, date, new_vaccinations
from covid.covid_vaccinations
;

/* 
-- If the data was correct the query I would perform next- using a temp table
create table if not exists percentage_population_vaccinated (
	Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated numeric
)
;
-- Using insert into to export the data into a temporary table
insert into percentage_population_vaccinated
select d.continent, d.location, d.date, d.population, v.new_vaccinations, 
sum(cast(v.new_vaccinations as decimal)) over (partition by d.location order by d.location, d.date) as rolling_people_vaccinated
from covid.covid_deaths as d
join covid.covid_vaccinations as v on v.date = d.date and v.location = d.location
order by d.location, d.date
;

-- Using a query to calculate the percentage of people vaccinated through the temporary table which was made
select *, rolling_people_vaccinated/population * 100 as percentage_vaccinated
from percentage_population_vaccinated
;
*/
