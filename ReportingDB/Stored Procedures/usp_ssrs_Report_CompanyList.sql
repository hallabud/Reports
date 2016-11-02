
--DECLARE @StartDate DATE = '2014-01-01';
--DECLARE @EndDate DATE = '2014-05-01';
--DECLARE @ManagerName VARCHAR(50) = 'Андрей Лёвин';
--DECLARE @YearNum INT = 2014;
--DECLARE @MonthNameRus VARCHAR(30) = 'Апрель';
--DECLARE @CompanyGroup VARCHAR(100) = 'Есть горячие публикации на счету или опубликованные горячие вакансии';
--DECLARE @Part VARCHAR(20) = 'Services';

CREATE PROCEDURE [dbo].[usp_ssrs_Report_CompanyList]
 (@StartDate DATE, @EndDate DATE, @ManagerName VARCHAR(50), @FullDate DATETIME, @YearNum INT = 2014, @MonthNameRus VARCHAR(30) = 'Апрель', @CompanyGroup VARCHAR(100), @Part VARCHAR(20))

 AS

IF OBJECT_ID('tempdb..#CompanyList','U') IS NOT NULL DROP TABLE #CompanyList;

CREATE TABLE #CompanyList (Company_key INT, NotebookId INT, CompanyName VARCHAR(300), HeadquarterCityID INT, ManagerName VARCHAR(50), FullDate DATETIME, YearNum INT, MonthNameRus VARCHAR(30), MonthNum INT, CompanyGroup VARCHAR(100), CardColor VARCHAR(20))

IF @Part = 'Publications'
BEGIN
INSERT INTO #CompanyList(Company_key, NotebookId, CompanyName, ManagerName, FullDate, YearNum, MonthNameRus, MonthNum, CompanyGroup, CardColor)
SELECT
   CS.Company_key
 , NC.NotebookId
 , NC.Name AS 'CompanyName'
 , M.Name AS 'ManagerName'
 , DD.FullDate
 , DD.YearNum
 , DD.MonthNameRus
 , DD.MonthNum
 , CASE 
    WHEN SUM(CAST(HasPaidPublishedVacs AS INT)) > 0 AND SUM(CAST(HasPaidPublicationsLeft AS INT)) > 0 THEN 'Есть платные публикации на счету и опубликованные платные вакансии'
    WHEN SUM(CAST(HasPaidPublicationsLeft AS INT)) > 0 THEN 'Есть платные публикации на счету, но нет опубликованных платных вакансий'
    WHEN SUM(CAST(HasPaidPublishedVacs AS INT)) > 0 THEN 'Нет платных публикаций на счету, но есть опубликованные платные вакансии'
    ELSE 'Нет платных публикаций на счету и нет опубликованных платных вакансий'
   END AS 'CompanyGroup'
 , CASE 
    WHEN SUM(CAST(HasPaidPublishedVacs AS INT)) > 0 AND SUM(CAST(HasPaidPublicationsLeft AS INT)) > 0 THEN 'green'
    WHEN SUM(CAST(HasPaidPublicationsLeft AS INT)) > 0 THEN 'lime'
    WHEN SUM(CAST(HasPaidPublishedVacs AS INT)) > 0 THEN 'yellow'
    ELSE 'red'
   END AS 'CardColor'
FROM Reporting.dbo.DimCompany DC
 JOIN Analytics.dbo.NotebookCompany NC ON DC.NotebookId = NC.NotebookId
 JOIN Analytics.dbo.Manager M ON NC.ManagerId = M.Id
 JOIN Reporting.dbo.FactCompanyStatuses CS ON DC.Company_key = CS.Company_key
 JOIN Reporting.dbo.DimDate DD ON CS.Date_key = DD.Date_key
WHERE DD.FullDate BETWEEN @StartDate AND @EndDate
 AND M.DepartmentID = 2
 AND M.Name IN (@ManagerName)
 AND EXISTS (SELECT * 
			 FROM Reporting.dbo.FactCompanyStatuses CS2
			  JOIN Reporting.dbo.DimDate DD2 ON CS2.Date_key = DD2.Date_key
			 WHERE CS2.Company_key = CS.Company_key 
			  AND DD2.FullDate BETWEEN @StartDate AND @EndDate
			  AND (HasPaidPublicationsLeft = 1 OR HasPaidPublishedVacs = 1))
GROUP BY  
   CS.Company_key 
 , NC.NotebookId
 , NC.Name
 , M.Name
 , DD.FullDate
 , DD.YearNum
 , DD.MonthNameRus
 , DD.MonthNum


SELECT * 
FROM #CompanyList
WHERE YearNum IN (@YearNum) AND MonthNameRus IN (@MonthNameRus) AND CompanyGroup IN (@CompanyGroup)
END

ELSE IF @Part = 'Services'
BEGIN
INSERT INTO #CompanyList(Company_key, NotebookId, CompanyName, HeadquarterCityID, ManagerName, FullDate, YearNum, MonthNameRus, MonthNum, CompanyGroup)
SELECT
   CS.Company_key
 , NC.NotebookId
 , NC.Name AS 'CompanyName'
 , NC.HeadquarterCityId
 , M.Name AS 'ManagerName'
 , DD.FullDate
 , DD.YearNum
 , DD.MonthNameRus
 , DD.MonthNum
 , CASE 
    WHEN CAST(HasPaidPublishedVacs AS INT) > 0 OR CAST(HasPaidPublicationsLeft AS INT) > 0 THEN 'Есть платные публикации на счету или опубликованные платные вакансии'
    WHEN CAST(HasHotPublishedVacs AS INT) > 0 OR CAST(HasHotPublicationsLeft AS INT) > 0 THEN 'Есть горячие публикации на счету или опубликованные горячие вакансии'
	WHEN CAST(HasCVDBAccess AS INT) > 0 THEN 'Есть доступ к базе резюме'
	WHEN CAST(HasActivatedLogo AS INT) > 0 OR CAST(HasActivatedProfile AS INT) > 0 THEN 'Клиенты по другому сервису (профиль/логотип)'
    ELSE 'Не использовали платный сервис'
   END AS 'CompanyGroup'
FROM Reporting.dbo.DimCompany DC
 JOIN Analytics.dbo.NotebookCompany NC ON DC.NotebookId = NC.NotebookId
 JOIN Analytics.dbo.Manager M ON NC.ManagerId = M.Id
 JOIN Reporting.dbo.FactCompanyStatuses CS ON DC.Company_key = CS.Company_key
 JOIN Reporting.dbo.DimDate DD ON CS.Date_key = DD.Date_key
WHERE DD.FullDate BETWEEN @StartDate AND @EndDate
 AND (DD.DayNum = 1 OR DD.FullDate = @EndDate)
 AND NC.IsNetworkCompany = 0
 AND M.DepartmentID = 2
 AND M.Name IN (@ManagerName)
 AND EXISTS (SELECT * 
			 FROM Reporting.dbo.FactCompanyStatuses CS2
			  JOIN Reporting.dbo.DimDate DD2 ON CS2.Date_key = DD2.Date_key
			 WHERE CS2.Company_key = CS.Company_key 
			  AND DD2.FullDate BETWEEN DATEADD(MONTH, -12, DD.FullDate) AND DD.FullDate
			  AND (HasPaidPublicationsLeft = 1 OR HasPaidPublishedVacs = 1 OR HasHotPublishedVacs = 1 OR HasHotPublicationsLeft = 1 OR HasCVDBAccess = 1 OR HasActivatedLogo = 1 OR HasActivatedProfile = 1))


SELECT * 
FROM #CompanyList
WHERE FullDate IN (@FullDate) AND CompanyGroup IN (@CompanyGroup)
END
