/*-----------------------------------------------------------------------------------------------------------------------------------------------
											
								COVID-19 PROJECT - DATA EXPLORATION 

Skills used: Joins, CTE, Temporary Tables, Subqueries, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types.

-------------------------------------------------------------------------------------------------------------------------------------------------*/


-- Data overview.

SELECT *
FROM [Covid19Project].[dbo].[covid_deaths]
ORDER BY 3,4

SELECT *
FROM [Covid19Project].[dbo].[covid_vaccinations]
ORDER BY 3,4


-- Selecting data I am going to explore further in upcoming queries.

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [Covid19Project].[dbo].[covid_deaths]
ORDER BY 1,2


/*-------------------------------------------------------- BREAKING DATA DOWN BY COUNTRY --------------------------------------------------------*/


-- Looking at the mortality rate of infected population (ratio of total deaths to total cases), shown as a percentage.

SELECT location, date, total_cases, total_deaths,
	FORMAT(ROUND(ISNULL(CONVERT(FLOAT,total_deaths),0)/NULLIF(CONVERT(FLOAT,total_cases),0), 4),'p') AS mortality_rate
FROM Covid19Project..covid_deaths
--WHERE location IN ('France', 'European Union', 'World')  -- Add to query if interested in specific areas.
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Looking at the infection rate (ratio of total cases to population), shown as a percentage.

SELECT location, date, population, total_cases,
	FORMAT(ROUND(ISNULL(CONVERT(FLOAT,total_cases),0)/CONVERT(FLOAT,population), 4),'p') AS infection_rate
FROM Covid19Project..covid_deaths
--WHERE location IN ('France', 'European Union', 'World')  -- Add to query if interested in specific areas.
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Looking at countries with the highest infection rates.

SELECT location, population,
	MAX(CONVERT(INT,total_cases)) AS highest_cases_count,
	FORMAT(ROUND(ISNULL(MAX(CONVERT(FLOAT,total_cases)),0)/population, 4),'p') AS highest_infection_rate
FROM Covid19Project..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY ROUND(ISNULL(MAX(CONVERT(FLOAT,total_cases)),0)/population, 4) DESC


-- Looking at countries with the highest death-by-covid rates compared to population.

SELECT location, population,
	MAX(CAST(total_deaths AS INT)) AS highest_deaths_count,
	CAST(ROUND(ISNULL(MAX(CONVERT(FLOAT,total_deaths)),0)*100/population, 4) AS NVARCHAR(10)) + '%' AS highest_death_rate
FROM Covid19Project..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY ISNULL(MAX(CONVERT(FLOAT,total_deaths)),0)/population DESC


/*------------------------------------------------------- BREAKING DATA DOWN BY CONTINENT -------------------------------------------------------*/


-- Looking at continents with the highest deaths-by-covid count.

SELECT continent, SUM(total_deaths_by_country) AS total_deaths_by_continent
		FROM (SELECT continent, location, MAX(CAST(total_deaths AS INT)) AS total_deaths_by_country
			  FROM Covid19Project..covid_deaths
			  WHERE continent IS NOT NULL
			  GROUP BY continent,location
			 ) continent_location_totCountryDeaths
GROUP BY continent
ORDER BY total_deaths_by_continent DESC


/*---------------------------------------------------------------- GLOBAL NUMBERS ----------------------------------------------------------------*/


-- Looking at the mortality rate of infected population globally (ratio of total deaths to total cases in the entire world) on each day, shown as a percentage.

SELECT date, SUM(new_cases) AS global_total_cases, SUM(new_deaths) AS global_total_deaths,
	FORMAT(ROUND(ISNULL(SUM(new_deaths),0)/NULLIF(SUM(new_cases),0), 4),'p') AS global_mortality_rate
FROM Covid19Project..covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


-- Looking at the mortality rate of infected population globally (ratio of total deaths to total cases in the entire world) overall, shown as a percentage.

SELECT SUM(new_cases) AS global_total_cases, SUM(new_deaths) AS global_total_deaths,
	FORMAT(ROUND(ISNULL(SUM(new_deaths),0)/NULLIF(SUM(new_cases),0), 4),'p') AS global_mortality_rate_overall
FROM Covid19Project..covid_deaths
WHERE continent IS NOT NULL


/*------------------------------------------------------------------ JOINED DATA -----------------------------------------------------------------*/


-- Joined data overview.

SELECT *
FROM Covid19Project..covid_deaths dea
JOIN Covid19Project..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
ORDER BY 3,4


-- Looking at cumulative total vaccinations for each country.

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations))
		OVER (PARTITION BY dea.location 
			  ORDER BY dea.location, dea.date
			  ) AS cumulative_total_vaccinations
FROM Covid19Project..covid_deaths dea
JOIN Covid19Project..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- Looking at the vaccination rates (ratio of total vaccinations to population) for each country, shown as a percentage. -- Using CTE.

WITH population_VS_vaccinations (continent, location, date, population, new_vaccinations, cumulative_total_vaccinations)
AS
(
 SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(FLOAT, vac.new_vaccinations))
		OVER (PARTITION BY dea.location 
			  ORDER BY dea.location, dea.date
			  ) AS cumulative_total_vaccinations
 FROM Covid19Project..covid_deaths dea
 JOIN Covid19Project..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL
)
SELECT *,
	FORMAT(ROUND(ISNULL(cumulative_total_vaccinations,0)/population, 4),'p') AS vaccination_rate
FROM population_VS_vaccinations
ORDER BY 2,3


-- Looking at the vaccination rates (ratio of total vaccinations to population) for each country, shown as a percentage. -- Using Temporary Table.

DROP TABLE IF EXISTS #temp_population_VS_vaccinations

CREATE TABLE #temp_population_VS_vaccinations (continent NVARCHAR(255),
											   location NVARCHAR(255),
											   date DATETIME,
											   population NUMERIC,
											   new_vaccinations NVARCHAR(255),
											   cumulative_total_vaccinations NUMERIC)

INSERT INTO #temp_population_VS_vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(FLOAT, vac.new_vaccinations))
		OVER (PARTITION BY dea.location 
			  ORDER BY dea.location, dea.date
			  ) AS cumulative_total_vaccinations
FROM Covid19Project..covid_deaths dea
JOIN Covid19Project..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *,
	FORMAT(ROUND(ISNULL(cumulative_total_vaccinations,0)/population, 4),'p') AS vaccination_rate
FROM #temp_population_VS_vaccinations
ORDER BY 2,3


/*-------------------------------------------------------------------- VIEWS --------------------------------------------------------------------*/


-- Creating a View to store data for later visualizations.

DROP VIEW IF EXISTS view_population_VS_vaccinations
GO

CREATE VIEW view_population_VS_vaccinations
AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(FLOAT, vac.new_vaccinations))
		OVER (PARTITION BY dea.location 
			  ORDER BY dea.location, dea.date
			  ) AS cumulative_total_vaccinations
FROM Covid19Project..covid_deaths dea
JOIN Covid19Project..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GO
