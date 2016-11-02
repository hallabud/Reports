
CREATE PROCEDURE [dbo].[usp_ssrs_ReportWorkVsRabotaActivityGroupsMonthly_Pivot]
 (@StartDate DATETIME, @EndDate DATETIME)

AS

DECLARE @FirstDate DATETIME;

IF OBJECT_ID('tempdb..#DateLookup','U') IS NOT NULL DROP TABLE #DateLookup;
IF OBJECT_ID('tempdb..#WorkHistoryLastMonths','U') IS NOT NULL DROP TABLE #WorkHistoryLastMonths;
IF OBJECT_ID('tempdb..#WorkCompanyStatuses','U') IS NOT NULL DROP TABLE #WorkCompanyStatuses;
IF OBJECT_ID('tempdb..#WorkActivityGroupsMonthly','U') IS NOT NULL DROP TABLE #WorkActivityGroupsMonthly;

CREATE TABLE #DateLookup
 (FullDate DATETIME NOT NULL,
  SixMonthAgoLastDate DATETIME NULL,
  ThreeMonthAgoLastDate DATETIME NULL,
  TwoMonthAgoLastDate DATETIME NULL);  

INSERT INTO #DateLookup
SELECT 
   DD.FullDate
 , (SELECT DD6.FullDate FROM dbo.DimDate DD6 WHERE DD6.IsLastDayOfMonth = 1 AND DATEDIFF(MONTH, DD6.FullDate, DD.FullDate) = 5) AS SixMonthAgoLastDate
 , (SELECT DD3.FullDate FROM dbo.DimDate DD3 WHERE DD3.IsLastDayOfMonth = 1 AND DATEDIFF(MONTH, DD3.FullDate, DD.FullDate) = 2) AS ThreeMonthAgoLastDate
 , (SELECT DD2.FullDate FROM dbo.DimDate DD2 WHERE DD2.IsLastDayOfMonth = 1 AND DATEDIFF(MONTH, DD2.FullDate, DD.FullDate) = 1) AS TwoMonthAgoLastDate
FROM Reporting.dbo.DimDate DD
WHERE DD.IsLastDayOfMonth = 1 AND DD.FullDate BETWEEN @StartDate AND @EndDate;

SELECT @FirstDate = MIN(SixMonthAgoLastDate) FROM #DateLookup;

CREATE TABLE #WorkHistoryLastMonths
 (CompanyID INT NOT NULL,
  Date DATETIME NOT NULL,
  VacancyCount INT, 
  HotVacancyCount INT,
  Paid BIT,
  IsPaidByTickets BIT,
  PRIMARY KEY (CompanyID, Date));


INSERT INTO #WorkHistoryLastMonths
SELECT 
   CompanyID
 , Date
 , VacancyCount
 , HotVacancyCount
 , Paid
 , IsPaidByTickets
FROM Analytics.dbo.SpiderCompanyWorkHistory SCH
WHERE SCH.Date BETWEEN @FirstDate AND @EndDate AND EXISTS (SELECT * FROM Reporting.dbo.DimDate DD WHERE SCH.Date = DD.FullDate AND DD.IsLastDayOfMonth = 1);

CREATE TABLE #WorkCompanyStatuses
 (CompanyID INT NOT NULL,
  FullDate DATETIME NOT NULL,
  IsSPD BIT NOT NULL,
  IsApproved BIT NOT NULL,
  HasPaidServices BIT NOT NULL,
  PublicationsLast6Month SMALLINT NOT NULL,
  PublicationsLast3Month SMALLINT NOT NULL,
  PublicationsLast2Month SMALLINT NOT NULL,
  MonthNumLast6Month SMALLINT NOT NULL,
  MonthNumLast3Month SMALLINT NOT NULL,
  MonthNumLast2Month SMALLINT NOT NULL,
  PRIMARY KEY (CompanyID, FulLDate));

INSERT INTO #WorkCompanyStatuses
SELECT
   SCH.CompanyId
 , SCH.Date
 , CASE WHEN SC.Name LIKE '% [ЧП]П' OR SC.Name LIKE '%Ф[ОЛ]П%' OR SC.Name LIKE '%СПД%' THEN 1 ELSE 0 END AS IsSPD
 , SC.IsApproved
 , CASE WHEN SCH.Paid = 1 OR SCH.IsPaidByTickets = 1 THEN 1 ELSE 0 END AS 'HasPaidServices'
 , (SELECT SUM(VacancyCount) 
	FROM #WorkHistoryLastMonths SCH6
	WHERE SCH6.CompanyID = SCH.CompanyID AND SCH6.Date BETWEEN DL.SixMonthAgoLastDate AND SCH.Date) AS PublicationsLast6Month
 , (SELECT SUM(VacancyCount) 
	FROM #WorkHistoryLastMonths SCH3 
	WHERE SCH3.CompanyID = SCH.CompanyID AND SCH3.Date BETWEEN DL.ThreeMonthAgoLastDate AND SCH.Date) AS PublicationsLast3Month
 , (SELECT SUM(VacancyCount) 
	FROM #WorkHistoryLastMonths SCH2 
	WHERE SCH2.CompanyID = SCH.CompanyID AND SCH2.Date BETWEEN DL.TwoMonthAgoLastDate AND SCH.Date) AS PublicationsLast2Month
 , (SELECT COUNT(DATEPART(MONTH, SCH6.Date)) 
	FROM #WorkHistoryLastMonths SCH6 
	WHERE SCH6.CompanyID = SCH.CompanyID AND SCH6.Date BETWEEN DL.SixMonthAgoLastDate AND SCH.Date
     AND SCH6.VacancyCount > 0) AS MonthNumLast6Month
 , (SELECT COUNT(DATEPART(MONTH, SCH3.Date)) 
	FROM #WorkHistoryLastMonths SCH3 
	WHERE SCH3.CompanyID = SCH.CompanyID AND SCH3.Date BETWEEN DL.ThreeMonthAgoLastDate AND SCH.Date
     AND SCH3.VacancyCount > 0) AS MonthNumLast3Month
 , (SELECT COUNT(DATEPART(MONTH, SCH2.Date))
	FROM #WorkHistoryLastMonths SCH2 
	WHERE SCH2.CompanyID = SCH.CompanyID AND SCH2.Date BETWEEN DL.TwoMonthAgoLastDate AND SCH.Date
     AND SCH2.VacancyCount > 0) AS MonthNumLast2Month
FROM Analytics.dbo.SpiderCompanyWorkHistory SCH
 JOIN Analytics.dbo.SpiderCompany SC ON SCH.CompanyID = SC.CompanyId AND SC.Source = 1
 JOIN #DateLookup DL ON SCH.Date = DL.FullDate;

SELECT 
   DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.FullDate
 , CONVERT(VARCHAR, DD.FullDate, 104) AS 'FullDate104'
 , IsSPD
 , IsApproved
 , HasPaidServices
 , CASE 
    WHEN PublicationsLast6Month >= 2 AND MonthNumLast6Month >= 2 AND PublicationsLast3Month >= 1
     THEN 1
    ELSE 0
   END AS 'IsActive6'
 , CASE 
    WHEN PublicationsLast3Month >= 2 AND MonthNumLast3Month >= 2
     THEN 1
    ELSE 0
   END AS 'IsActive3' 
 , CASE 
    WHEN PublicationsLast2Month >= 2 AND MonthNumLast2Month >= 2
     THEN 1
    ELSE 0
   END AS 'IsActive2' 
 , COUNT(DISTINCT CompanyID) AS CompaniesNum
INTO #WorkActivityGroupsMonthly
FROM #WorkCompanyStatuses WCS
 JOIN Reporting.dbo.DimDate DD ON WCS.FullDate = DD.FullDate
GROUP BY
   DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.FullDate
 , CONVERT(VARCHAR, DD.FullDate, 104)
 , IsSPD
 , IsApproved
 , HasPaidServices
 , CASE 
    WHEN PublicationsLast6Month >= 2 AND MonthNumLast6Month >= 2 AND PublicationsLast3Month >= 1
     THEN 1
    ELSE 0
   END
 , CASE 
    WHEN PublicationsLast3Month >= 2 AND MonthNumLast3Month >= 2
     THEN 1
    ELSE 0
   END
 , CASE 
    WHEN PublicationsLast2Month >= 2 AND MonthNumLast2Month >= 2
     THEN 1
    ELSE 0
   END;

WITH CTE AS
 (
SELECT 
   'work.ua' AS Source
 , FullDate
 , FullDate104
 , IsActive6
 , IsActive3
 , IsActive2
 , CompaniesNum
FROM #WorkActivityGroupsMonthly
WHERE HasPaidServices = 1 OR (HasPaidServices = 0 AND IsApproved = 1 AND IsSPD = 0)
UNION ALL
SELECT 
   'rabota.ua'
 , DATEADD(DAY,-1,vw.FullDate)
 , FullDate104
 , IsActive6
 , IsActive3
 , IsActive2
 , CompaniesNum
FROM dbo.vw_CompaniesActivityGroupsMonthly vw
 JOIN #DateLookup DL ON DATEADD(DAY,-1,vw.FullDate) = DL.FullDate
WHERE IsMegaChecked = 1 OR (IsMegaChecked = 0 AND HasPaidServices = 1)
 )
 , CTE_PIVOT AS
 (
SELECT 
   FullDate
 , FullDate104
 , IsActive6
 , IsActive3
 , IsActive2
 , [rabota.ua] AS 'rabota.ua'
 , [work.ua] AS 'work.ua'
FROM 
(SELECT * FROM CTE) p
PIVOT
(SUM(CompaniesNum)
FOR Source IN ([rabota.ua],[work.ua])
) AS pvt
 )
 , CTE_Final AS
 (
SELECT 
  'Active2' AS ActivityGroup
, FullDate
, FullDate104
, SUM([rabota.ua]) AS [rabota.ua]
, SUM([work.ua]) AS [work.ua]
FROM CTE_PIVOT
WHERE IsActive2 = 1
GROUP BY 
  FullDate
, FullDate104
UNION ALL
SELECT 
  'Active3' AS ActivityGroup
, FullDate
, FullDate104
, SUM([rabota.ua]) AS [rabota.ua]
, SUM([work.ua]) AS [work.ua]
FROM CTE_PIVOT
WHERE IsActive3 = 1
GROUP BY 
  FullDate
, FullDate104
UNION ALL
SELECT 
  'Active6' AS ActivityGroup
, FullDate
, FullDate104
, SUM([rabota.ua]) AS [rabota.ua]
, SUM([work.ua]) AS [work.ua]
FROM CTE_PIVOT
WHERE IsActive6 = 1
GROUP BY 
  FullDate
, FullDate104
 )

SELECT 
   ActivityGroup 
 , FullDate
 , FullDate104
 , [rabota.ua]
 , [work.ua]
 , CASE 
	WHEN dbo.fnGetMinimumOf2Values([rabota.ua],[work.ua]) = 0 THEN NULL
	ELSE CAST(1.0 * ([rabota.ua] - [work.ua]) / dbo.fnGetMinimumOf2Values([rabota.ua],[work.ua]) AS decimal(8,4))
   END AS 'GAP'
FROM CTE_Final
ORDER BY ActivityGroup, FullDate

DROP TABLE #DateLookup;
DROP TABLE #WorkHistoryLastMonths;
DROP TABLE #WorkCompanyStatuses;
DROP TABLE #WorkActivityGroupsMonthly;
