
CREATE PROCEDURE [dbo].[usp_ssrs_Report_SpiderVacancyDiff]

AS

DECLARE @EndDate DATE = GETDATE();
DECLARE @StartDate DATE = DATEADD(DAY, 1 - DAY(DATEADD(MONTH, -6, @EndDate)), DATEADD(MONTH, -6, @EndDate));
DECLARE @LastDates TABLE (FullDate DATE);

INSERT INTO @LastDates
SELECT FullDate 
FROM Reporting.dbo.DimDate DD
WHERE DD.FullDate BETWEEN @StartDate AND @EndDate
 AND DD.IsLastDayOfMonth = 1;

IF OBJECT_ID('tempdb..#FirstPubDates','U') IS NOT NULL DROP TABLE #FirstPubDates;
IF OBJECT_ID('tempdb..#RabotaVacancyNum','U') IS NOT NULL DROP TABLE #RabotaVacancyNum;
IF OBJECT_ID('tempdb..#WorkVacancyNum','U') IS NOT NULL DROP TABLE #WorkVacancyNum;

CREATE TABLE #FirstPubDates (NotebookID INT PRIMARY KEY, FirstPubDate DATE);
CREATE TABLE #RabotaVacancyNum (FullDate DATE, NotebookID INT, VacancyNum INT, PRIMARY KEY (NotebookID, FullDate));
CREATE TABLE #WorkVacancyNum (FullDate DATE, CompanyId INT, VacancyNum INT, PRIMARY KEY (CompanyID, FullDate));

INSERT INTO #FirstPubDates
SELECT NotebookID, MIN(AddDate)
FROM Analytics.dbo.NotebookCompany_Spent NCS
GROUP BY NotebookID;


INSERT INTO #RabotaVacancyNum
SELECT
   Dfrom.LastMonthDate AS FullDate
 , NC.NotebookID
 , COUNT(DISTINCT VSH.VacancyId)
FROM Analytics.dbo.VacancyStateHistory AS VSH 
 INNER JOIN Analytics.dbo.Vacancy AS V ON VSH.VacancyId = V.Id 
 INNER JOIN Analytics.dbo.NotebookCompany AS NC ON V.NotebookId = NC.NotebookId 
 INNER JOIN Analytics.dbo.Notebook AS N ON NC.NotebookId = N.Id
 INNER JOIN Reporting.dbo.DimDate AS Dfrom ON VSH.DateFrom = Dfrom.DaysFrom20060101 
 LEFT OUTER JOIN Reporting.dbo.DimDate AS Dto ON VSH.DateTo = Dto.DaysFrom20060101
WHERE (VSH.State = 4) AND (Dfrom.LastMonthDate BETWEEN @StartDate AND @EndDate) AND (VSH.DateTo - VSH.DateFrom = 29) 
 OR (VSH.State = 4 AND Dfrom.LastMonthDate BETWEEN @StartDate AND @EndDate AND VSH.DateTo IS NULL)
 OR (VSH.State = 4 AND Dfrom.LastMonthDate BETWEEN @StartDate AND @EndDate AND VSH.DateTo - VSH.DateFrom <> 29 AND Dto.FullDate >= Dfrom.LastMonthDate)
GROUP BY Dfrom.LastMonthDate, NC.NotebookID;

INSERT INTO #WorkVacancyNum
SELECT Reporting.dbo.fnGetDatePart(SCH.AddDate), SC.CompanyID, MAX(SCH.VacancyCount)
FROM Analytics.dbo.SpiderCompanyHistory SCH
 JOIN Analytics.dbo.SpiderCompany SC ON SCH.SpiderCompanyID = SC.ID AND SC.Source = 1
 JOIN Reporting.dbo.DimDate DD ON Reporting.dbo.fnGetDatePart(SCH.AddDate) = DD.FullDate
WHERE SCH.AddDate BETWEEN @StartDate AND @EndDate
 AND DD.IsLastDayOfMonth = 1 AND SCH.VacancyCount > 0
GROUP BY Reporting.dbo.fnGetDatePart(SCH.AddDate), SC.CompanyID;


SELECT NC.NotebookId, SC.CompanyId, COALESCE(NC.HeadquarterCityId, SC.CityID) AS CityId
 , CASE WHEN DepartmentID IS NULL OR DepartmentID <> 2 THEN 'SMB' ELSE 'SF' END AS Department
 , M.Id AS ManagerID
 , LD.FullDate
 , ISNULL(RVN.VacancyNum,0) AS RabotaVacancyNum
 , ISNULL(WVN.VacancyNum,0) AS WorkVacancyNum
 , ISNULL(RVN.VacancyNum,0) - ISNULL(WVN.VacancyNum,0) AS VacancyDiff
 , CASE 
    WHEN ISNULL(RVN.VacancyNum,0) > 0 AND ISNULL(WVN.VacancyNum,0) = 0 THEN 'R>0 , W=0'
	WHEN ISNULL(WVN.VacancyNum,0) > 0 AND ISNULL(RVN.VacancyNum,0) = 0 THEN 'W>0 , R=0'
	WHEN ISNULL(WVN.VacancyNum,0) = ISNULL(RVN.VacancyNum,0) THEN 'W=R'
	WHEN ISNULL(WVN.VacancyNum,0) > 0 AND ISNULL(WVN.VacancyNum,0) > ISNULL(RVN.VacancyNum,0) THEN 'W>0  и больше чем R, R не = 0'
	WHEN ISNULL(RVN.VacancyNum,0) > 0 AND ISNULL(RVN.VacancyNum,0) > ISNULL(WVN.VacancyNum,0) THEN 'R>0  и больше чем W, W не = 0'
   END AS VacancyDiffGroup
 , CASE 
    WHEN NC.NotebookID IS NULL THEN 'Компания на work.ua без привязки к компании на rabota.ua'
	WHEN SC.CompanyID IS NULL THEN 'Компания на rabota.ua без привязки к компании на work.ua'
    WHEN NC.NotebookID IS NOT NULL AND SC.CompanyID IS NOT NULL AND EXISTS (SELECT * FROM Analytics.dbo.SpiderCompanyHistory WHERE Source = 1 AND SpiderCompanyId = SC.ID AND VacancyCount > 0 AND AddDate >= DATEADD(YEAR, -1, LD.FullDate)) THEN 'Привязанные компании'
	ELSE 'Компания на rabota.ua без привязки к компании на work.ua'
   END AS CompanyGroup
FROM Analytics.dbo.NotebookCompany NC
 FULL JOIN Analytics.dbo.SpiderCompany SC ON NC.NotebookID = SC.NotebookId AND SC.Source = 1
 LEFT JOIN Analytics.dbo.Notebook N ON NC.NotebookId = N.Id
 LEFT JOIN Analytics.dbo.Manager M ON NC.ManagerID = M.Id
 LEFT JOIN #FirstPubDates FPD ON NC.NotebookId = FPD.NotebookID
 CROSS JOIN @LastDates LD
 LEFT JOIN #RabotaVacancyNum RVN ON NC.NotebookId = RVN.NotebookID AND LD.FullDate = RVN.FullDate
 LEFT JOIN #WorkVacancyNum WVN ON SC.CompanyId = WVN.CompanyId AND LD.FullDate = WVN.FullDate
WHERE 
 (N.NotebookStateId IS NULL OR N.NotebookStateId = 7) -- Мегапроверенные у нас
 AND (SC.IsApproved IS NULL OR SC.IsApproved = 1) -- Проверенные у них
 AND (SC.AddDate IS NULL OR SC.AddDate <= DATEADD(MONTH, -4, LD.FullDate)) -- подростки и взрослые на ворке
 AND ((SC.CompanyID IS NOT NULL AND FPD.FirstPubDate IS NULL) OR FPD.FirstPubDate <= DATEADD(MONTH, -4, LD.FullDate)) -- подростки и взрослые у нас
 AND (ISNULL(RVN.VacancyNum,0) > 0 OR ISNULL(WVN.VacancyNum,0) > 0) -- есть хотя бы одна вакансия на ворк или не работе
ORDER BY CompanyGroup, NotebookID, CompanyId, FullDate;

DROP TABLE #FirstPubDates;
DROP TABLE #RabotaVacancyNum;
DROP TABLE #WorkVacancyNum;

