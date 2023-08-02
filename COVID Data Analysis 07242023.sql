
SELECT *
FROM ProjectPortfolio.dbo.[COVID Deaths]
WHERE continent is not null
ORDER by 3,4 
OFFSET 0 rows
FETCH next 100 rows only;

SELECT Location, 
	   date, 
	   total_cases, 
	   new_cases, 
	   total_deaths, 
	   population
FROM ProjectPortfolio.dbo.[COVID Deaths]
ORDER by 1,2

--Looking at Total Cases v. Total Deaths
--Shows the likelihood of dying by COVID if contracted

SELECT Location, 
	   date, 
	   total_cases, 
	   total_deaths, 
	   (total_deaths/total_cases)*100 as DeathPercentage
FROM ProjectPortfolio.dbo.[COVID Deaths]
WHERE location like '%states%'
ORDER by 1,2

--Looking at Total cases v population

SELECT Location, 
	   date, 
	   population, 
	   total_cases, 
	   (total_cases/population) *100 as InfectionRate
FROM ProjectPortfolio.dbo.[COVID Deaths]
ORDER by 1,2

--Looking at which Country has the Highest Infection Rate compare to Population

SELECT Location, 
	   population, 
	   MAX(total_cases) as HighestInfectionCount, 
	   MAX((total_cases/population)) *100 as InfectionRate
FROM ProjectPortfolio.dbo.[COVID Deaths]
GROUP by population, location
ORDER by InfectionRate desc

--Breaking things down by continent 


--Continents and Income brackets were included in the same column
--Needed to modify query in order to exclude income
SELECT location, 
	   MAX(cast(total_deaths as int)) as TotalDeathCount
FROM ProjectPortfolio.dbo.[COVID Deaths]
WHERE continent is null and 
	  location not like '%income%' 
GROUP by location
ORDER by TotalDeathCount desc

--Showing continents with the Highest Death Count per population
SELECT location, 
	   MAX(cast(total_deaths as int)) as TotalDeathCount
FROM ProjectPortfolio.dbo.[COVID Deaths]
WHERE 
	continent is null and 
	location not like '%income%' and 
	location not like '%world%'
GROUP by location
ORDER by TotalDeathCount desc

--GLOBAL NUMBERS

--Mortality Rate over time
SELECT date, 
	   SUM(new_cases) as total_cases, 
	   SUM(new_deaths) as total_deaths,
	   ISNULL(SUM(new_deaths)/NULLIF((SUM(new_cases)),0),0) *100 as DeathPercentage
FROM ProjectPortfolio..[COVID Deaths]
WHERE continent is not null 
GROUP by date
ORDER by 1,2

--Total Mortality Rate of the world
SELECT SUM(new_cases) as total_cases, 
	   SUM(new_deaths) as total_deaths,
	   ISNULL(SUM(new_deaths)/NULLIF((SUM(new_cases)),0),0) *100 as DeathPercentage
FROM ProjectPortfolio..[COVID Deaths]
WHERE continent is not null 
ORDER by 1,2

--MOVING OVER TO VAX RATES

--Looking at total population v. vaccination
SELECT dea.continent, 
	   dea.location, 
	   dea.date, 
	   dea.population, 
	   vax.new_vaccinations, 
	   SUM(CONVERT(bigint, vax.new_vaccinations)) 
			OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaxed
FROM ProjectPortfolio..[COVID Deaths] dea
	Join ProjectPortfolio..[COVID Vax] vax
		on dea.location = vax.location
		and dea.date = vax.date
WHERE dea.continent is not null
ORDER by 2,3

--Making a CTE
WITH PopVSVax (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaxed)
as 
(
SELECT dea.continent, 
	   dea.location, 
	   dea.date, 
	   dea.population, 
	   vax.new_vaccinations, 
	   SUM(CONVERT(bigint, vax.new_vaccinations)) 
			OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaxed
FROM ProjectPortfolio..[COVID Deaths] dea
	Join ProjectPortfolio..[COVID Vax] vax
		on dea.location = vax.location
		and dea.date = vax.date
WHERE 
   dea.continent is not null
   and new_vaccinations is not null
)

SELECT *, 
	(RollingPeopleVaxed/Population) * 100
FROM PopVSVax


--TEMP TABLE
DROP Table if exists #PercentPopulationVaxed
CREATE Table #PercentPopulationVaxed
(
Continent nvarchar(225), 
location nvarchar(225), 
date datetime,
population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT into #PercentPopulationVaxed
SELECT dea.continent, 
	   dea.location, 
	   dea.date, 
	   dea.population, 
	   vax.new_vaccinations, 
	   SUM(CONVERT(bigint, vax.new_vaccinations)) 
			OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM ProjectPortfolio..[COVID Deaths] dea
Join ProjectPortfolio..[COVID Vax] vax
	on dea.location = vax.location
	and dea.date = vax.date
WHERE dea.continent is not null

Select *, (RollingPeopleVaccinated/Population) * 100 as PercentageVaccinated
FROM #PercentPopulationVaxed


--Creating view  to store data for later visualization
USE ProjectPortfolio
GO
CREATE VIEW PercentPopulationVaccinated as
Select dea.continent, 
	   dea.location, 
	   dea.date, 
	   dea.population, 
	   vax.new_vaccinations, 
	   SUM(CONVERT(bigint, vax.new_vaccinations)) 
			OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM ProjectPortfolio..[COVID Deaths] dea
Join ProjectPortfolio..[COVID Vax] vax
	on dea.location = vax.location
	and dea.date = vax.date
WHERE dea.continent is not null


SELECT * 
FROM PercentPopulationVaccinated