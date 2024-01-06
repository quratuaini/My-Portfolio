/* COVID 19 Data Exploration */

/* Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types */

SELECT *
FROM DataExplorationProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

-- Select the data that we are going to be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM DataExplorationProject..CovidDeaths
ORDER BY 1,2

-- Total Death VS Total Cases
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM DataExplorationProject..CovidDeaths
WHERE location = 'Indonesia' AND continent IS NOT NULL
ORDER BY 1,2

-- Total Cases VS Total Population
-- Shows what percentage of population infected with covid

SELECT location, date, population, total_cases, (total_cases/population) * 100 AS PercentPopulationInfected
FROM DataExplorationProject..CovidDeaths
ORDER BY 1,2

-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population) * 100 AS PercentPopulationInfected
FROM DataExplorationProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths as INT)) AS TotalDeathCount
FROM DataExplorationProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT continent, MAX(CAST(total_deaths as INT)) AS TotalDeathCount
FROM DataExplorationProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases) * 100 AS DeathPercentage
FROM DataExplorationProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Total Population VS Vaccinations
-- Shows Percentage of Population that has received at least one covid vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM DataExplorationProject..CovidDeaths dea
JOIN DataExplorationProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Using CTE to perform calculation on Partition by in previous query

WITH PopvsVac(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM DataExplorationProject..CovidDeaths dea
JOIN DataExplorationProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population) * 100
FROM PopvsVac

-- Using Temp Table to perfotm calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinates
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinates
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM DataExplorationProject..CovidDeaths dea
JOIN DataExplorationProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

SELECT *,(RollingPeopleVaccinated/Population) * 100
FROM #PercentPopulationVaccinates

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM DataExplorationProject..CovidDeaths dea
JOIN DataExplorationProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL