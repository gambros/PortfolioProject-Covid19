/*-----------------------------------------------------------------------------------------------------------------------------------------------
											
														COVID-19 PROJECT - TABLEAU VISUALIZATION 

-------------------------------------------------------------------------------------------------------------------------------------------------*/


/*--------------------------------------------------------------- GLOBAL NUMBERS ----------------------------------------------------------------*/


-- Looking at the global mortality rate of infected population overall (ratio of total deaths to total cases in the entire world), shown as a percentage.

SELECT SUM(new_cases) AS global_total_cases, SUM(new_deaths) AS global_total_deaths,
	FORMAT(ROUND(ISNULL(SUM(new_deaths),0)/NULLIF(SUM(new_cases),0), 4),'p') AS global_mortality_rate_overall
FROM [Covid19Project].[dbo].[covid_deaths]
WHERE continent IS NOT NULL 


-- Creating a View to store data from above query for Tableau visualizations.

DROP VIEW IF EXISTS view_global_numbers
GO
CREATE VIEW view_global_numbers
AS
SELECT SUM(new_cases) AS global_total_cases, SUM(new_deaths) AS global_total_deaths,
	FORMAT(ROUND(ISNULL(SUM(new_deaths),0)/NULLIF(SUM(new_cases),0), 4),'p') AS global_mortality_rate_overall
FROM [Covid19Project].[dbo].[covid_deaths]
WHERE continent IS NOT NULL
GO


/*----------------------------------------------- BREAKING DATA DOWN BY CONTINENT - DEATHS COUNT ------------------------------------------------*/


-- Looking at deaths-by-covid count for each continent.

SELECT location, SUM(new_deaths) AS total_deaths_by_continent
FROM Covid19Project..covid_deaths
WHERE continent IS NULL 
	AND location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY total_deaths_by_continent DESC


-- Creating a View to store data from above query for Tableau visualizations.

DROP VIEW IF EXISTS view_deaths_count
GO
CREATE VIEW view_deaths_count
AS
SELECT location, SUM(new_deaths) AS total_deaths_by_continent
FROM Covid19Project..covid_deaths
WHERE continent IS NULL 
	AND location NOT IN ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
GO


/*----------------------------------------- BREAKING DATA DOWN BY COUNTRY - POPULATION INFECTION RATES ------------------------------------------*/


-- Looking at the infection rates (ratio of total cases to population) for each country, shown as a percentage.

SELECT location, population,
	SUM(new_cases) AS highest_cases_count,
	FORMAT(ROUND(ISNULL(SUM(new_cases),0)/population, 4),'p') AS highest_infection_rate
FROM Covid19Project..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY ROUND(ISNULL(SUM(new_cases),0)/population, 4) DESC


-- Creating a View to store data from above query for Tableau visualizations.

DROP VIEW IF EXISTS view_population_infection_rates
GO
CREATE VIEW view_population_infection_rates
AS
SELECT location, population,
	SUM(new_cases) AS highest_cases_count,
	FORMAT(ROUND(ISNULL(SUM(new_cases),0)/population, 4),'p') AS highest_infection_rate
FROM Covid19Project..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
GO


/*----------------------------------------- BREAKING DATA DOWN BY COUNTRY - INFECTED POPULATION GROWTH ------------------------------------------*/


-- Looking at the growth of infected population (ratio of total cases to population) over time, for each country.

SELECT location, population, date,
	ISNULL(MAX(CAST(total_cases AS FLOAT)),0) AS total_cases_count,
	CAST(ROUND(ISNULL(MAX(CAST(total_cases AS FLOAT)),0)*100/population, 6) AS NVARCHAR(10)) + '%' AS infection_rate -- dealing with small percentages
FROM Covid19Project..covid_deaths
WHERE continent IS NOT NULL --AND location = 'United States' -- location filter
GROUP BY Location, Population, date
ORDER BY date, ISNULL(MAX(CAST(total_cases AS FLOAT)),0)/population DESC

-- Alternative (same output of above query): calculating the total cases as cumulative count of new cases.
SELECT location, population, date,
	SUM(new_cases) OVER (PARTITION BY location ORDER BY location, date) AS cumulative_cases_count,
	CAST(ROUND(ISNULL(SUM(new_cases) OVER (PARTITION BY location ORDER BY location, date),0)*100/population, 6) AS VARCHAR(10)) + '%' AS cumulative_infection_rate
FROM Covid19Project..covid_deaths
WHERE continent IS NOT NULL --AND location = 'United States' -- location filter
ORDER BY date, cumulative_infection_rate DESC


-- Creating a View to store data from above query for Tableau visualizations.

DROP VIEW IF EXISTS view_infected_population_growth
GO
CREATE VIEW view_infected_population_growth
AS
SELECT location, population, date,
	ISNULL(MAX(CAST(total_cases AS FLOAT)),0) AS total_cases_count,
	CAST(ROUND(ISNULL(MAX(CAST(total_cases AS FLOAT)),0)*100/population, 6) AS NVARCHAR(10)) + '%' AS infection_rate -- dealing with small percentages
FROM Covid19Project..covid_deaths
WHERE continent IS NOT NULL --AND location = 'United States' -- location filter
GROUP BY Location, Population, date
GO