
CREATE PROCEDURE [dbo].[usp_ValuableVacancyIndex]

AS

-- индекс ценности на работе.юа

TRUNCATE TABLE Reporting.dbo.NotebookIndexValuableVacancy;

WITH C AS
 (
SELECT NC.NotebookID, NC.Name
 , ISNULL(100. * (SELECT COUNT(*) FROM Analytics.dbo.Vacancy V WHERE V.NotebookId = NC.NotebookId AND V.ProfLevelID > 1) / NULLIF((SELECT COUNT(*) FROM Analytics.dbo.Vacancy V WHERE V.NotebookId = NC.NotebookId AND V.ProfLevelID IS NOT NULL),0),0) AS ValuableWeight
FROM Analytics.dbo.NotebookCompany NC 
 )

INSERT INTO Reporting.dbo.NotebookIndexValuableVacancy
SELECT NotebookId
 , CASE 
    WHEN ValuableWeight BETWEEN 0 AND 10 THEN 0.55
	WHEN ValuableWeight BETWEEN 10 AND 20 THEN 0.6
	WHEN ValuableWeight BETWEEN 20 AND 30 THEN 0.65
	WHEN ValuableWeight BETWEEN 30 AND 40 THEN 0.7
	WHEN ValuableWeight BETWEEN 40 AND 50 THEN 0.75
	WHEN ValuableWeight BETWEEN 50 AND 60 THEN 0.8
	WHEN ValuableWeight BETWEEN 60 AND 70 THEN 0.85
	WHEN ValuableWeight BETWEEN 70 AND 80 THEN 0.9
	WHEN ValuableWeight BETWEEN 80 AND 90 THEN 0.95
	WHEN ValuableWeight BETWEEN 90 AND 100 THEN 1
   END AS IndexValuable
FROM C 


-- индекс ценности на ворк.юа
IF OBJECT_ID('tempdb..#SynonymProfLevels','U') IS NOT NULL DROP TABLE #SynonymProfLevels;
IF OBJECT_ID('tempdb..#SpiderVacancyProfLevels','U') IS NOT NULL DROP TABLE #SpiderVacancyProfLevels;

SELECT SG.Name, MAX(SPF.ProfLevelID) AS ProfLevelID
INTO #SynonymProfLevels
FROM Analytics.dbo.SynonymGroup_ProfLevel SPF
 JOIN Analytics.dbo.SynonymGroup SG ON SPF.SynonymousID = SG.SynonymousID
GROUP BY SG.Name

SELECT SV.ID, SV.Name, SC.CompanyId, MAX(SPF.ProfLevelID) AS ProfLevelID
INTO #SpiderVacancyProfLevels
FROM Analytics.dbo.SpiderVacancy SV
 JOIN Analytics.dbo.SpiderCompany SC ON SV.SpiderCompanyID = SC.CompanyId AND SC.Source = 1
 JOIN #SynonymProfLevels SPF ON SV.Name LIKE '%' + SPF.Name + '%' 
WHERE SV.Source = 1
GROUP BY SV.ID, SV.Name, SC.CompanyId;

TRUNCATE TABLE Reporting.dbo.NotebookIndexValuableVacancy_Work;

WITH C AS
 (
SELECT SC.CompanyID
 , SC.Name
 , ISNULL(100. * (SELECT COUNT(*) FROM #SpiderVacancyProfLevels SVPF WHERE SVPF.CompanyId = SC.CompanyId AND Source = 1 AND SVPF.ProfLevelID > 1) / NULLIF((SELECT COUNT(*) FROM #SpiderVacancyProfLevels SVPF WHERE SVPF.CompanyId = SC.CompanyId AND Source = 1),0),0) AS ValuableWeight
FROM Analytics.dbo.SpiderCompany SC
WHERE SC.Source = 1
 )
INSERT INTO Reporting.dbo.NotebookIndexValuableVacancy_Work
SELECT CompanyId
 , CASE 
    WHEN ValuableWeight BETWEEN 0 AND 10 THEN 0.55
	WHEN ValuableWeight BETWEEN 10 AND 20 THEN 0.6
	WHEN ValuableWeight BETWEEN 20 AND 30 THEN 0.65
	WHEN ValuableWeight BETWEEN 30 AND 40 THEN 0.7
	WHEN ValuableWeight BETWEEN 40 AND 50 THEN 0.75
	WHEN ValuableWeight BETWEEN 50 AND 60 THEN 0.8
	WHEN ValuableWeight BETWEEN 60 AND 70 THEN 0.85
	WHEN ValuableWeight BETWEEN 70 AND 80 THEN 0.9
	WHEN ValuableWeight BETWEEN 80 AND 90 THEN 0.95
	WHEN ValuableWeight BETWEEN 90 AND 100 THEN 1
   END AS IndexValuable
FROM C 
ORDER BY IndexValuable DESC, ValuableWeight DESC

DROP TABLE #SynonymProfLevels;
DROP TABLE #SpiderVacancyProfLevels;