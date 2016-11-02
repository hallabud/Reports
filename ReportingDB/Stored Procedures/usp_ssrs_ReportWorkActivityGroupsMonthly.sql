
CREATE PROCEDURE [dbo].[usp_ssrs_ReportWorkActivityGroupsMonthly]

AS

IF OBJECT_ID('tempdb..#DateLookup','U') IS NOT NULL DROP TABLE #DateLookup;
IF OBJECT_ID('tempdb..#DistinctWorkCompaniesVacs','U') IS NOT NULL DROP TABLE #DistinctWorkCompaniesVacs;
IF OBJECT_ID('tempdb..#WorkCompanyStatuses','U') IS NOT NULL DROP TABLE #WorkCompanyStatuses;
IF OBJECT_ID('tempdb..#WorkActivityGroupsMonthly','U') IS NOT NULL DROP TABLE #WorkActivityGroupsMonthly;

CREATE TABLE #DateLookup
 (FullDate DATETIME NOT NULL,
  SixMonthAgoLastDate DATETIME NULL,
  ThreeMonthAgoLastDate DATETIME NULL,
  TwoMonthAgoLastDate DATETIME NULL,
  CONSTRAINT PK_DateLookup PRIMARY KEY (FullDate));  

CREATE TABLE #DistinctWorkCompaniesVacs
 (FullDate DATETIME NOT NULL,
  SpiderCompanyID INT NOT NULL,
  IsSPD BIT NOT NULL,
  IsApproved BIT NULL,
  VacancyCount SMALLINT NULL,
  HotVacancyCount SMALLINT NULL,
  Paid BIT NULL,
  IsPaidByTickets BIT NULL,
  CONSTRAINT PK_DistinctWorkCompaniesVacs PRIMARY KEY (SpiderCompanyID, FullDate));

CREATE TABLE #WorkCompanyStatuses
 (SpiderCompanyID INT NOT NULL,
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
  CONSTRAINT PK_WorkCompanyStatuses PRIMARY KEY (SpiderCompanyID, FullDate));

INSERT INTO #DateLookup
SELECT 
   DD.FullDate
 , (SELECT DD6.FullDate FROM dbo.DimDate DD6 WHERE DD6.IsLastDayOfMonth = 1 AND DATEDIFF(MONTH, DD6.FullDate, DD.FullDate) = 5) AS SixMonthAgoLastDate
 , (SELECT DD3.FullDate FROM dbo.DimDate DD3 WHERE DD3.IsLastDayOfMonth = 1 AND DATEDIFF(MONTH, DD3.FullDate, DD.FullDate) = 2) AS ThreeMonthAgoLastDate
 , (SELECT DD2.FullDate FROM dbo.DimDate DD2 WHERE DD2.IsLastDayOfMonth = 1 AND DATEDIFF(MONTH, DD2.FullDate, DD.FullDate) = 1) AS TwoMonthAgoLastDate
FROM Reporting.dbo.DimDate DD
WHERE DD.IsLastDayOfMonth = 1;

INSERT INTO #DistinctWorkCompaniesVacs
SELECT 
   Reporting.dbo.fnGetDatePart(SCH.AddDate)
 , SCH.SpiderCompanyId
 , MAX(CAST((CASE WHEN SC.Name LIKE '% [ЧП]П' OR SC.Name LIKE '%Ф[ОЛ]П%' OR SC.Name LIKE '%СПД%' THEN 1 ELSE 0 END) AS TINYINT))
 , MAX(CAST(SC.IsApproved AS TINYINT))
 , MAX(SCH.VacancyCount)
 , MAX(SCH.HotVacancyCount)
 , MAX(CAST(SCH.Paid AS TINYINT))
 , MAX(CAST(SCH.IsPaidByTickets AS TINYINT))
FROM Analytics.dbo.SpiderCompanyHistory SCH
 JOIN Analytics.dbo.SpiderCompany SC ON SCH.SpiderCompanyID = SC.Id
WHERE SC.Source = 1
 AND Reporting.dbo.fnGetDatePart(SCH.AddDate) IN (SELECT FullDate FROM Reporting.dbo.DimDate WHERE IsLastDayOfMonth = 1)
GROUP BY 
   Reporting.dbo.fnGetDatePart(SCH.AddDate)
 , SCH.SpiderCompanyId;

INSERT INTO #WorkCompanyStatuses
SELECT
   WCV.SpiderCompanyID
 , WCV.FullDate
 , WCV.IsSPD
 , WCV.IsApproved
 , CASE WHEN WCV.Paid = 1 OR WCV.IsPaidByTickets = 1 THEN 1 ELSE 0 END AS 'HasPaidServices'
 , (SELECT SUM(VacancyCount) 
	FROM #DistinctWorkCompaniesVacs WCV6 
	WHERE WCV6.SpiderCompanyID = WCV.SpiderCompanyID AND WCV6.FullDate BETWEEN DL.SixMonthAgoLastDate AND WCV.FullDate) AS PublicationsLast6Month
 , (SELECT SUM(VacancyCount) 
	FROM #DistinctWorkCompaniesVacs WCV3 
	WHERE WCV3.SpiderCompanyID = WCV.SpiderCompanyID AND WCV3.FullDate BETWEEN DL.ThreeMonthAgoLastDate AND WCV.FullDate) AS PublicationsLast3Month
 , (SELECT SUM(VacancyCount) 
	FROM #DistinctWorkCompaniesVacs WCV2 
	WHERE WCV2.SpiderCompanyID = WCV.SpiderCompanyID AND WCV2.FullDate BETWEEN DL.TwoMonthAgoLastDate AND WCV.FullDate) AS PublicationsLast2Month
 , (SELECT COUNT(DATEPART(MONTH, WCV6.FullDate)) 
	FROM #DistinctWorkCompaniesVacs WCV6 
	WHERE WCV6.SpiderCompanyID = WCV.SpiderCompanyID AND WCV6.FullDate BETWEEN DL.SixMonthAgoLastDate AND WCV.FullDate
     AND WCV6.VacancyCount > 0) AS MonthNumLast6Month
 , (SELECT COUNT(DATEPART(MONTH, WCV3.FullDate)) 
	FROM #DistinctWorkCompaniesVacs WCV3 
	WHERE WCV3.SpiderCompanyID = WCV.SpiderCompanyID AND WCV3.FullDate BETWEEN DL.ThreeMonthAgoLastDate AND WCV.FullDate
     AND WCV3.VacancyCount > 0) AS MonthNumLast3Month
 , (SELECT COUNT(DATEPART(MONTH, WCV2.FullDate))
	FROM #DistinctWorkCompaniesVacs WCV2 
	WHERE WCV2.SpiderCompanyID = WCV.SpiderCompanyID AND WCV2.FullDate BETWEEN DL.TwoMonthAgoLastDate AND WCV.FullDate
     AND WCV2.VacancyCount > 0) AS MonthNumLast2Month
FROM #DistinctWorkCompaniesVacs WCV
 JOIN #DateLookup DL ON WCV.FullDate = DL.FullDate
WHERE WCV.FullDate >= '2012-12-31';

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
 , COUNT(DISTINCT SpiderCompanyID) AS CompaniesNum
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

SELECT * FROM #WorkActivityGroupsMonthly

DROP TABLE #DateLookup;
DROP TABLE #DistinctWorkCompaniesVacs;
DROP TABLE #WorkCompanyStatuses;
DROP TABLE #WorkActivityGroupsMonthly;
