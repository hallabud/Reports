CREATE PROCEDURE [dbo].[usp_etl_GetVacancyNumsLast3Month]

AS

DECLARE @TodayDate DATETIME = dbo.fnGetDatePart(GETDATE());
DECLARE @Month1LastDate DATETIME = DATEADD(DAY, - DAY(@TodayDate), @TodayDate);
DECLARE @Month2LastDate DATETIME = DATEADD(DAY, - DAY(DATEADD(MONTH, -1, @TodayDate)), DATEADD(MONTH, -1, @TodayDate));
DECLARE @Month3LastDate DATETIME = DATEADD(DAY, - DAY(DATEADD(MONTH, -2, @TodayDate)), DATEADD(MONTH, -2, @TodayDate));

IF OBJECT_ID('tempdb..#RabotaVacancyNum','U') IS NOT NULL DROP TABLE #RabotaVacancyNum;
IF OBJECT_ID('tempdb..#WorkVacancyNum','U') IS NOT NULL DROP TABLE #WorkVacancyNum;

CREATE TABLE #WorkVacancyNum (FullDate DATE, CompanyId INT, VacancyNum INT, PRIMARY KEY (CompanyID, FullDate));
CREATE TABLE #RabotaVacancyNum (FullDate DATE, NotebookID INT, VacancyNum INT, PRIMARY KEY (NotebookID, FullDate));

INSERT INTO #WorkVacancyNum
SELECT DD.FullDate, DSC.CompanyID, FSCI.VacancyCount
FROM Reporting.dbo.DimSpiderCompany DSC
 JOIN Reporting.dbo.FactSpiderCompanyIndexes FSCI ON DSC.SpiderCompanyID = FSCI.SpiderCompanyID
 JOIN Reporting.dbo.DimDate DD ON FSCI.Date_key = DD.Date_key
WHERE DD.FullDate IN (@Month1LastDate, @Month2LastDate, @Month3LastDate)
 AND DSC.SpiderSource_key = 1
 AND FSCI.VacancyCount > 0
ORDER BY DSC.CompanyID, DD.FullDate;


INSERT INTO #RabotaVacancyNum
SELECT
   Dfrom.LastMonthDate AS FullDate
 , NC.NotebookID
 , COUNT(DISTINCT VSH.VacancyId) AS VacancyNum
FROM SRV16.RabotaUA2.dbo.VacancyStateHistory VSH WITH (NOLOCK)
 JOIN SRV16.RabotaUA2.dbo.Vacancy V WITH (NOLOCK) ON VSH.VacancyId = V.Id 
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC WITH (NOLOCK) ON V.NotebookId = NC.NotebookId 
 JOIN SRV16.RabotaUA2.dbo.Notebook N WITH (NOLOCK) ON NC.NotebookId = N.Id
 JOIN Reporting.dbo.DimDate Dfrom ON VSH.DateFrom = Dfrom.DaysFrom20060101 
 LEFT OUTER JOIN Reporting.dbo.DimDate AS Dto ON VSH.DateTo = Dto.DaysFrom20060101
WHERE (VSH.State = 4) AND (Dfrom.LastMonthDate BETWEEN @Month3LastDate AND @Month1LastDate) AND (VSH.DateTo - VSH.DateFrom = 29) 
 OR (VSH.State = 4 AND Dfrom.LastMonthDate BETWEEN @Month3LastDate AND @Month1LastDate AND VSH.DateTo IS NULL)
 OR (VSH.State = 4 AND Dfrom.LastMonthDate BETWEEN @Month3LastDate AND @Month1LastDate AND VSH.DateTo - VSH.DateFrom <> 29 AND Dto.FullDate >= Dfrom.LastMonthDate)
GROUP BY Dfrom.LastMonthDate, NC.NotebookID;

SELECT FullDate, NotebookID, VacancyNum, 'rabota.ua' AS Source
FROM #RabotaVacancyNum 
 
 UNION ALL

SELECT FullDate, CompanyID, VacancyNum, 'work.ua' AS Source
FROM #WorkVacancyNum;

DROP TABLE #WorkVacancyNum;
DROP TABLE #RabotaVacancyNum;
