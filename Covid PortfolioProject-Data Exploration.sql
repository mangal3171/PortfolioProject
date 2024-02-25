/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 3,4

-- Selecting Data that we are going to be working with


Select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
Where continent is not null
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in India


Select location, date, population, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths
where location = 'India' and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid in India


Select location, date, population, total_cases, (total_cases/population)*100 as InfectionRate
from CovidDeaths
where location = 'India' and continent is not null 
order by 1,2


-- Countries with Highest Infection Rate compared to Population


Select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as InfectionRate
from CovidDeaths
where continent is not null 
Group by location, population
order by InfectionRate desc


-- Countries with Highest Death Count in a day


Select location, MAX(cast(total_deaths as int)) as HighestDeathCount
from CovidDeaths
where continent is not null 
Group by location
order by HighestDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count in a day


Select continent, MAX(cast(total_deaths as int)) as HighestDeathCount
from CovidDeaths
where continent is not null 
Group by continent
order by HighestDeathCount desc


-- GLOBAL NUMBERS


Select SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, 
SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
where continent is not null 
order by 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
-- Using CTE to perform Calculation on Partition By


WITH VaccinationRolling AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    FROM CovidDeaths dea
    JOIN CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT continent, location, date, population, new_vaccinations, RollingPeopleVaccinated,
       (RollingPeopleVaccinated / population) * 100 AS VaccinationPercentage
FROM VaccinationRolling
ORDER BY 2, 3


-- Using Temp Table to perform Calculation on Partition By in previous query


DROP Table if exists #VaccinationPercentage
Create Table #VaccinationPercentage
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #VaccinationPercentage
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #VaccinationPercentage


-- Creating View to store data for later visualizations

Create View VaccinationPercentage as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
