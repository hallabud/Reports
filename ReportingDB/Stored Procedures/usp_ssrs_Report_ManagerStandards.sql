
-- ========================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: Unknown
-- ========================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Modify date: 2016-10-11
-- Description:	Входящие параметры процедуры
--				@StartDate - начальная дата
--				@EndDate - конечная дата
--				@CompanyFilter - параметр, влияющий на набор компаний, по которым считается 
--				% уникальных вакансий.
--					1 - Все компании
--					2 - Не брать в расчет те компании, которые "взяты в работу недавно" (до 3-х месяцев).
--						Смотрим по полю ManagerStartDate таблицы Reporting.dbo.DimCompany.
-- ========================================================================================================
-- ========================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Modify date: 2016-10-12
-- Description:	Меняем логику.
--				Раньше - отображались данные только по тем менеджерам, которые выполнили как минимум одно
--				действие в выбранном периоде
--				Теперь - выводим всех менеджеров вне зависимости от того были ли у них выполненные 
--				действия (список менеджеров - во временную таблицу #Managers
-- ========================================================================================================
-- ========================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Modify date: 2016-10-13
-- Description:	MeetingsCountMonth - вместо кол-ва встреч за месяц от @EndDate - 1 мес. до @EndDate, 
--				считаем кол-во встреч в календарном (соответствующем @EndDate) месяце.
-- ========================================================================================================
-- ========================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Modify date: 2016-10-13
-- Description:	Добавлен параметр @ManagerAge - количество полных месяцев от даты добавления менеджера
--				в базу до даты @EndDate
-- ========================================================================================================

CREATE PROCEDURE [dbo].[usp_ssrs_Report_ManagerStandards]
 @StartDate DATETIME, @EndDate DATETIME, @CompanyFilter TINYINT = 2, @ManagerAge INT = 0

AS

-- -------------------------------------------------
-- для тестирования: вместо входящих параметров процедуры
 --DECLARE @StartDate DATETIME = '2016-10-13';
 --DECLARE @EndDate DATETIME = '2016-10-13';
 --DECLARE @CompanyFilter TINYINT = 2;
 --DECLARE @ManagerAge INT = 0;
-- -------------------------------------------------

DECLARE @OrderManagerAge TINYINT = 2; -- количество месяцев стажа, влияющее на сортировку в отчете
DECLARE @EndDateMinusWeek DATETIME; SET @EndDateMinusWeek = DATEADD(DAY, -6, @EndDate);
DECLARE @MayDay DATE = '2016-04-01';
DECLARE @Today DATE = CONVERT(DATE, GETDATE());
DECLARE @ThreeMonthAgo DATE = DATEADD(MONTH, -3, @Today);
DECLARE @MonthFirstDate DATETIME; SELECT @MonthFirstDate = DATEADD(MONTH, -1, @EndDate);
DECLARE @CalendarMonthFirstDate DATETIME; SELECT @CalendarMonthFirstDate = FirstMonthDate FROM dbo.DimDate WHERE FullDate = @EndDate;
DECLARE @StartDate_key INT; SELECT @StartDate_key = Date_key FROM Reporting.dbo.DimDate WHERE FullDate = @StartDate;
DECLARE @EndDate_key INT; SELECT @EndDate_key = Date_key FROM Reporting.dbo.DimDate WHERE FullDate = @EndDate;
DECLARE @MonthFirstDateKey INT; SELECT @MonthFirstDateKey = Date_key FROM Reporting.dbo.DimDate WHERE FullDate = @MonthFirstDate; 

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

IF OBJECT_ID('tempdb..#CompaniesWithCrmActions','U') IS NOT NULL DROP TABLE #CompaniesWithCrmActions;
IF OBJECT_ID('tempdb..#CompaniesWithCrmMeetings','U') IS NOT NULL DROP TABLE #CompaniesWithCrmMeetings;
IF OBJECT_ID('tempdb..#MetaNotebooksWithCrmActions','U') IS NOT NULL DROP TABLE #MetaNotebooksWithCrmActions;
IF OBJECT_ID('tempdb..#CompaniesWithCrmMeetingsWeek','U') IS NOT NULL DROP TABLE #CompaniesWithCrmMeetingsWeek;
IF OBJECT_ID('tempdb..#CompaniesWithCrmActionsMonth','U') IS NOT NULL DROP TABLE #CompaniesWithCrmActionsMonth;
IF OBJECT_ID('tempdb..#CompaniesWithCrmMeetingsMonth','U') IS NOT NULL DROP TABLE #CompaniesWithCrmMeetingsMonth;
IF OBJECT_ID('tempdb..#MetaNotebooksWithCrmActionsMonth','U') IS NOT NULL DROP TABLE #MetaNotebooksWithCrmActionsMonth;
IF OBJECT_ID('tempdb..#ActiveCompanies','U') IS NOT NULL DROP TABLE #ActiveCompanies;
IF OBJECT_ID('tempdb..#ActiveCompaniesMonth','U') IS NOT NULL DROP TABLE #ActiveCompaniesMonth;
IF OBJECT_ID('tempdb..#HasPaidServices','U') IS NOT NULL DROP TABLE #HasPaidServices;
IF OBJECT_ID('tempdb..#Managers','U') IS NOT NULL DROP TABLE #Managers;

CREATE TABLE #CompaniesWithCrmActions 
	(SalesTeam VARCHAR(100), 
	 ManagerID SMALLINT,
	 OrderNum INT,
	 ManagerEmail VARCHAR(200),
	 Manager VARCHAR(100), 
	 CompanyNum INT);

CREATE TABLE #CompaniesWithCrmMeetings
	(ManagerID SMALLINT, 
	 MeetingsCount INT);

CREATE TABLE #MetaNotebooksWithCrmActions
	(ManagerID SMALLINT, 
	 MetaNotebookNum INT);

CREATE TABLE #CompaniesWithCrmMeetingsWeek
	(ManagerID SMALLINT,
	 CompanyNumWeek INT);

CREATE TABLE #CompaniesWithCrmActionsMonth
	(ManagerID SMALLINT,
	 CompanyNumMonth INT);

CREATE TABLE #CompaniesWithCrmMeetingsMonth
	(ManagerID SMALLINT, 
	 MeetingsCountMonth INT);

CREATE TABLE #MetaNotebooksWithCrmActionsMonth
	(ManagerID SMALLINT,
	 MetaNotebookNumMonth INT);

CREATE TABLE #ActiveCompanies
	(ManagerEmail VARCHAR(200),
	 ActiveCompanyNum INT);

CREATE TABLE #ActiveCompaniesMonth
	(ManagerEmail VARCHAR(200),
	 ActiveCompanyNumMonth INT);

CREATE TABLE #HasPaidServices
	(ManagerEmail VARCHAR(200),
	 CompanyNumPaid INT);

SELECT 
	Id AS ManagerID
	, CASE WHEN dbo.udf_FullMonthsSeparation(M.AddDate, @EndDate) >= @OrderManagerAge THEN 0 ELSE 1 END AS OrderNum 
	, Name AS ManagerName 
	, COALESCE(TeamLead_ManagerID, Id) AS TeamLead_ManagerID
	, IsLoyaltyGroup
	, MMB.LoweredEmail AS Email
INTO #Managers
FROM Analytics.dbo.Manager M
	JOIN Analytics.dbo.aspnet_Membership MMB ON M.aspnet_UserUIN = MMB.UserId
WHERE DepartmentID IN (2,3,4)
	AND IsForTesting = 0
	AND IsReportExcluding = 0
	AND (TeamLead_ManagerID IS NOT NULL OR EXISTS (SELECT * FROM Analytics.dbo.Manager WHERE TeamLead_ManagerID = M.Id))
	AND dbo.udf_FullMonthsSeparation(M.AddDate, @EndDate) >= @ManagerAge;

-- Кол-во блокнотов, по которым были СРМ-действия менеджеров в отчетном периоде
WITH CrmActions AS
 (
SELECT A.Responsible, COUNT(DISTINCT NotebookID) AS CompanyNum
FROM SRV16.RabotaUA2.dbo.CRM_Action A
WHERE A.StateID = 2
 AND A.TypeID NOT IN (6,8,9)
 AND A.CompleteDate BETWEEN @StartDate AND @EndDate + 1
 AND EXISTS (SELECT * FROM #Managers WHERE Email = A.Responsible)
GROUP BY A.Responsible
 )
INSERT INTO #CompaniesWithCrmActions (SalesTeam, ManagerID, OrderNum, ManagerEmail, Manager, CompanyNum)
SELECT 
   'Команда "' + COALESCE(TL.Name, M.ManagerName) + '"' AS SalesTeam
 , M.ManagerID
 , M.OrderNum
 , M.Email AS ManagerEmail
 , M.ManagerName AS Manager
 , ISNULL(CA.CompanyNum, 0) AS CompanyNum
FROM #Managers M
 LEFT JOIN SRV16.RabotaUA2.dbo.Manager TL ON M.TeamLead_ManagerID = TL.ID
 LEFT JOIN CrmActions CA ON M.Email = CA.Responsible;

-- Кол-во блокнотов, по которым были СРМ-действия с типом действия = "встреча"
INSERT INTO #CompaniesWithCrmMeetings (ManagerID, MeetingsCount)
SELECT M.Id, COUNT(DISTINCT NotebookID)
FROM SRV16.RabotaUA2.dbo.CRM_Action A
 JOIN SRV16.RabotaUA2.dbo.aspnet_Membership AM ON A.Responsible = AM.Email
 JOIN SRV16.RabotaUA2.dbo.Manager M ON AM.UserID = M.aspnet_UserUIN
 JOIN SRV16.RabotaUA2.dbo.Departments D ON M.DepartmentID = D.ID
WHERE A.StateID = 2
 AND D.ID IN (2,3,4)
 AND TypeID = 8
 AND IsForTesting = 0 AND IsReportExcluding = 0
 AND CompleteDate BETWEEN @StartDate AND @EndDate + 1
GROUP BY M.Id;

-- Кол-во мета-блокнотов, по которым были СРМ-действия
INSERT INTO #MetaNotebooksWithCrmActions (ManagerID, MetaNotebookNum)
SELECT M.Id, COUNT(DISTINCT MetaNotebookID)
FROM SRV16.RabotaUA2.dbo.CRM_Action A
 JOIN SRV16.RabotaUA2.dbo.aspnet_Membership AM ON A.Responsible = AM.Email
 JOIN SRV16.RabotaUA2.dbo.Manager M ON AM.UserID = M.aspnet_UserUIN
 JOIN SRV16.RabotaUA2.dbo.Departments D ON M.DepartmentID = D.ID
WHERE A.NotebookID IS NULL
 AND A.StateID = 2
 AND D.ID IN (2,3,4)
 AND TypeID NOT IN (6,8,9)
 AND IsForTesting = 0 AND IsReportExcluding = 0
 AND CompleteDate BETWEEN @StartDate AND @EndDate + 1
GROUP BY M.Id;

-- Кол-во блокнотов, по которым были СРМ-действия менеджеров в течении месяца
INSERT INTO #CompaniesWithCrmActionsMonth (ManagerID, CompanyNumMonth)
SELECT M.Id AS ManagerID, COUNT(DISTINCT A.NotebookID)
FROM SRV16.RabotaUA2.dbo.CRM_Action A
 JOIN SRV16.RabotaUA2.dbo.aspnet_Membership AM ON A.Responsible = AM.Email
 JOIN SRV16.RabotaUA2.dbo.Manager M ON AM.UserID = M.aspnet_UserUIN
 JOIN SRV16.RabotaUA2.dbo.Departments D ON M.DepartmentID = D.ID
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC ON A.NotebookID = NC.NotebookID
WHERE A.StateID = 2
 AND D.ID IN (2,3,4)
 AND M.Id = NC.ManagerID
 AND TypeID NOT IN (6,8,9)
 AND IsForTesting = 0 AND IsReportExcluding = 0
 AND CompleteDate BETWEEN @MonthFirstDate AND @EndDate + 1
 AND EXISTS (SELECT * 
			 FROM Reporting.dbo.FactCompanyStatuses FCS
			  JOIN Reporting.dbo.DimDate DD ON FCS.Date_key = DD.Date_key
			  JOIN Reporting.dbo.DimCompany DC ON FCS.Company_key = DC.Company_key
			 WHERE DC.NotebookId = A.NotebookID
			  AND FCS.Date_key BETWEEN @MonthFirstDateKey AND @EndDate_key 
			  AND (FCS.VacancyNum > 0 OR FCS.WorkVacancyNum > 0))
GROUP BY M.Id;

-- Кол-во блокнотов, по которым были СРМ-действия менеджеров с типом действия = "встреча" в течении недели
INSERT INTO #CompaniesWithCrmMeetingsWeek (ManagerID, CompanyNumWeek)
SELECT M.Id AS ManagerID, COUNT(DISTINCT A.NotebookID)
FROM SRV16.RabotaUA2.dbo.CRM_Action A
 JOIN SRV16.RabotaUA2.dbo.aspnet_Membership AM ON A.Responsible = AM.Email
 JOIN SRV16.RabotaUA2.dbo.Manager M ON AM.UserID = M.aspnet_UserUIN
 JOIN SRV16.RabotaUA2.dbo.Departments D ON M.DepartmentID = D.ID
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC ON A.NotebookID = NC.NotebookID
WHERE A.StateID = 2
 AND D.ID IN (2,3,4)
 AND M.Id = NC.ManagerID
 AND TypeID = 8
 AND IsForTesting = 0 AND IsReportExcluding = 0
 AND CompleteDate BETWEEN @EndDateMinusWeek AND @EndDate + 1
 AND EXISTS (SELECT * 
			 FROM Reporting.dbo.FactCompanyStatuses FCS
			  JOIN Reporting.dbo.DimDate DD ON FCS.Date_key = DD.Date_key
			  JOIN Reporting.dbo.DimCompany DC ON FCS.Company_key = DC.Company_key
			 WHERE DC.NotebookId = A.NotebookID
			  AND FCS.Date_key BETWEEN @MonthFirstDateKey AND @EndDate_key 
			  AND (FCS.VacancyNum > 0 OR FCS.WorkVacancyNum > 0))
GROUP BY M.Id;

-- Кол-во блокнотов, по которым были СРМ-действия с типом действия = "встреча" в течении месяца
INSERT INTO #CompaniesWithCrmMeetingsMonth (ManagerID, MeetingsCountMonth)
SELECT M.Id AS ManagerID, COUNT(DISTINCT NotebookID) AS MeetingsCountMonth
FROM SRV16.RabotaUA2.dbo.CRM_Action A 
 JOIN SRV16.RabotaUA2.dbo.aspnet_Membership AM ON A.Responsible = AM.Email
 JOIN SRV16.RabotaUA2.dbo.Manager M ON AM.UserID = M.aspnet_UserUIN
 JOIN SRV16.RabotaUA2.dbo.Departments D ON M.DepartmentID = D.ID
WHERE A.StateID = 2
 AND D.ID IN (2,3,4)
 AND TypeID = 8
 AND IsForTesting = 0 AND IsReportExcluding = 0
 AND CompleteDate BETWEEN @CalendarMonthFirstDate AND @EndDate + 1
GROUP BY M.Id;

-- Кол-во мета-блокнотов, по которым были СРМ-действия в течении месяца
INSERT INTO #MetaNotebooksWithCrmActionsMonth (ManagerID, MetaNotebookNumMonth)
SELECT M.Id AS ManagerID, COUNT(DISTINCT MetaNotebookID)
FROM SRV16.RabotaUA2.dbo.CRM_Action A
 JOIN SRV16.RabotaUA2.dbo.aspnet_Membership AM ON A.Responsible = AM.Email
 JOIN SRV16.RabotaUA2.dbo.Manager M ON AM.UserID = M.aspnet_UserUIN
 JOIN SRV16.RabotaUA2.dbo.Departments D ON M.DepartmentID = D.ID
WHERE A.NotebookID IS NULL
 AND A.StateID = 2
 AND D.ID IN (2,3,4)
 AND TypeID NOT IN (6,8,9)
 AND IsForTesting = 0 AND IsReportExcluding = 0
 AND CompleteDate BETWEEN @MonthFirstDate AND @EndDate + 1
GROUP BY M.Id;

-- Кол-во активных компаний в отчетном периоде
INSERT INTO #ActiveCompanies (ManagerEmail, ActiveCompanyNum)
SELECT DC.ManagerEmail, COUNT(DISTINCT DC.Company_key) AS ActiveCompanyNum
FROM Reporting.dbo.DimCompany DC
WHERE EXISTS (SELECT * FROM Reporting.dbo.FactCompanyStatuses FCS WHERE FCS.Company_key = DC.Company_key AND Date_key BETWEEN @StartDate_key AND @EndDate_key AND VacancyNum | ISNULL(WorkVacancyNum,0) > 0)
GROUP BY DC.ManagerEmail;

-- Кол-во активных компаний в течении месяца
INSERT INTO #ActiveCompaniesMonth (ManagerEmail, ActiveCompanyNumMonth)
SELECT DC.ManagerEmail, COUNT(DISTINCT DC.Company_key) AS ActiveCompanyNumMonth
FROM Reporting.dbo.DimCompany DC
WHERE EXISTS (SELECT * FROM Reporting.dbo.FactCompanyStatuses FCS WHERE FCS.Company_key = DC.Company_key AND Date_key BETWEEN @MonthFirstDateKey AND @EndDate_key AND VacancyNum | ISNULL(WorkVacancyNum,0) > 0)
GROUP BY DC.ManagerEmail;

-- Кол-во компаний с платным сервисом
INSERT INTO #HasPaidServices (ManagerEmail, CompanyNumPaid)
SELECT DC.ManagerEmail, COUNT(DISTINCT FCS.Company_key) AS CompanyNumPaid
FROM Reporting.dbo.FactCompanyStatuses FCS
 JOIN Reporting.dbo.DimCompany DC ON FCS.Company_key = DC.Company_key
WHERE FCS.Date_key BETWEEN @StartDate_key AND @EndDate_key
 AND FCS.HasPaidServices = 1
GROUP BY DC.ManagerEmail;

WITH C AS
 (
SELECT A.*
 , ISNULL(M.MeetingsCount,0) AS MeetingsCount
 , ISNULL(MN.MetaNotebookNum,0) AS MetaNotebookNum
 , ISNULL(AM.CompanyNumMonth, 0) AS CompanyNumMonth
 , ISNULL(MM.MeetingsCountMonth, 0) AS MeetingsCountMonth
 , ISNULL(MNM.MetaNotebookNumMonth, 0) AS MetaNotebookNumMonth
 , ISNULL(AC.ActiveCompanyNum, 0) AS ActiveCompanyNum
 , ISNULL(ACM.ActiveCompanyNumMonth,0) AS ActiveCompanyNumMonth
 , ISNULL(PS.CompanyNumPaid, 0) AS CompanyNumPaid
 , ISNULL(MW.CompanyNumWeek, 0) AS MeetingsCountWeek
FROM #CompaniesWithCrmActions A
 LEFT JOIN #CompaniesWithCrmMeetings M ON A.ManagerID = M.ManagerID
 LEFT JOIN #MetaNotebooksWithCrmActions MN ON A.ManagerID = MN.ManagerID
 LEFT JOIN #CompaniesWithCrmActionsMonth AM ON A.ManagerID = AM.ManagerID
 LEFT JOIN #CompaniesWithCrmMeetingsMonth MM ON A.ManagerID = MM.ManagerID
 LEFT JOIN #MetaNotebooksWithCrmActionsMonth MNM ON A.ManagerID = MNM.ManagerID
 LEFT JOIN #ActiveCompanies AC ON A.ManagerEmail = AC.ManagerEmail
 LEFT JOIN #ActiveCompaniesMonth ACM ON A.ManagerEmail = ACM.ManagerEmail
 LEFT JOIN #HasPaidServices PS ON A.ManagerEmail = PS.ManagerEmail
 LEFT JOIN #CompaniesWithCrmMeetingsWeek MW ON A.ManagerID = MW.ManagerID
 )
 , C_Loyalty_Dates AS
 (
SELECT DC.ManagerEmail, FCS.Date_key
 , CASE 
    WHEN FCS.VacancyDiffGroup IN ('R > W = 0','R > W > 0', 'R = W') THEN 'Green'
	ELSE 'Red'
   END AS Color
 , COUNT(DISTINCT DC.Company_key) AS CompanyNum
FROM Reporting.dbo.DimCompany DC
 JOIN Reporting.dbo.FactCompanyStatuses FCS ON DC.Company_key = FCS.Company_key AND FCS.Date_key BETWEEN @StartDate_key AND @EndDate_key
WHERE FCS.VacancyDiffGroup <> 'R = W = 0' 
 AND DC.WorkConnectionGroup = 'Привязанные компании'
GROUP BY DC.ManagerEmail, FCS.Date_key
 , CASE 
    WHEN FCS.VacancyDiffGroup IN ('R > W = 0','R > W > 0', 'R = W') THEN 'Green'
	ELSE 'Red'
   END
 )
 , C_Loyalty AS
 (
SELECT ManagerEmail, AVG(LoyaltyCompanyNum) AS LoyaltyCompanyNum, AVG(Loyalty) AS AvgLoyalty
FROM 
	(
		SELECT ManagerEmail, Date_key, [Green] + [Red] AS LoyaltyCompanyNum, 1. * [Green] / ([Green] + [Red]) AS Loyalty
		FROM C_Loyalty_Dates p
		PIVOT
		(
		SUM(CompanyNum)
		FOR Color IN ([Green],[Red])
		) AS pvt
	) AS PVT_T
GROUP BY ManagerEmail
 )
 , C_UnqTarget AS
  (
SELECT ManagerEmail, AVG(UnqTarget) AS UnqTarget, AVG(UnqCompanyNum) AS UnqCompanyNum, AVG(UnqVacancyNum) AS UnqVacancyNum
FROM
	(
	SELECT FCS.Date_key, DC.ManagerEmail, 1. * SUM(FCS.VacancyNum) / NULLIF((SUM(FCS.VacancyNum) + SUM(FCS.UnqWorkVacancyNum)),0) AS UnqTarget, COUNT(DISTINCT DC.NotebookID) AS UnqCompanyNum, SUM(FCS.VacancyNum) AS UnqVacancyNum
	FROM Reporting.dbo.DimCompany DC
	 JOIN Reporting.dbo.FactCompanyStatuses FCS ON DC.Company_key = FCS.Company_key
	WHERE DC.WorkConnectionGroup = 'Привязанные компании'
	 AND DC.IndexAttraction > 0
	 AND FCS.VacancyDiffGroup <> 'R = W = 0'
	 AND FCS.Date_key BETWEEN @MonthFirstDateKey AND @EndDate_key
	 AND (ManagerStartDate < CASE WHEN @CompanyFilter = 1 THEN @Today ELSE @MayDay END OR ManagerStartDate < CASE WHEN @CompanyFilter = 1 THEN @Today ELSE @ThreeMonthAgo END) -- Компания взята в работу менеджером или до 1/04/2016, или не позже чем 3 мес. назад
	GROUP BY FCS.Date_key, DC.ManagerEmail
	) A
GROUP BY ManagerEmail
 )

SELECT 
   C.SalesTeam
 , C.Manager
 , C.OrderNum
 , C.CompanyNum + C.MetaNotebookNum AS CompanyNum
 , C.CompanyNumMonth + C.MetaNotebookNumMonth AS CompanyNumMonth
 , C.MeetingsCount
 , C.MeetingsCountWeek
 , C.MeetingsCountMonth
 , CAST(100. * C.CompanyNum / NULLIF(C.ActiveCompanyNum,0) AS DECIMAL(5,1)) AS Coverage
 , CAST(100. * C.CompanyNumMonth / NULLIF(C.ActiveCompanyNumMonth,0) AS DECIMAL(5,1)) AS CoverageMonth
 , C.ActiveCompanyNum
 , C.ActiveCompanyNumMonth
 , CAST(CL.AvgLoyalty * 100 AS DECIMAL(5,1)) AS AvgLoyalty
 , CL.LoyaltyCompanyNum
 , CAST(UT.UnqTarget * 100 AS DECIMAL(5,1)) AS UnqTarget
 , UT.UnqCompanyNum
 , UT.UnqVacancyNum
 , C.CompanyNumPaid
FROM C
 LEFT JOIN C_Loyalty CL ON C.ManagerEmail = CL.ManagerEmail
 LEFT JOIN C_UnqTarget UT ON C.ManagerEmail = UT.ManagerEmail

UNION ALL

SELECT 
   C.SalesTeam
 , 'Все'
 , 0
 , AVG(C.CompanyNum + C.MetaNotebookNum) AS CompanyNum
 , AVG(C.CompanyNumMonth + C.MetaNotebookNumMonth) AS CompanyNumMonth
 , AVG(C.MeetingsCount)
 , AVG(C.MeetingsCountWeek)
 , AVG(C.MeetingsCountMonth)
 , CAST(AVG(100. * C.CompanyNum / NULLIF(C.ActiveCompanyNum,0)) AS DECIMAL(5,1)) AS Coverage
 , CAST(AVG(100. * C.CompanyNumMonth / NULLIF(C.ActiveCompanyNumMonth,0)) AS DECIMAL(5,1)) AS CoverageMonth
 , AVG(C.ActiveCompanyNum)
 , AVG(C.ActiveCompanyNumMonth)
 , CAST(AVG(CL.AvgLoyalty * 100) AS DECIMAL(5,1)) AS AvgLoyalty
 , AVG(CL.LoyaltyCompanyNum)
 , CAST(AVG(UT.UnqTarget * 100) AS DECIMAL(5,1)) AS UnqTarget
 , AVG(UT.UnqCompanyNum)
 , AVG(UT.UnqVacancyNum)
 , AVG(C.CompanyNumPaid)
FROM C
 LEFT JOIN C_Loyalty CL ON C.ManagerEmail = CL.ManagerEmail
 LEFT JOIN C_UnqTarget UT ON C.ManagerEmail = UT.ManagerEmail
GROUP BY C.SalesTeam

UNION ALL

SELECT 
   'Все'
 , 'Все'
 , 0
 , AVG(C.CompanyNum + C.MetaNotebookNum) AS CompanyNum
 , AVG(C.CompanyNumMonth + C.MetaNotebookNumMonth) AS CompanyNumMonth
 , AVG(C.MeetingsCount)
 , AVG(C.MeetingsCountWeek)
 , AVG(C.MeetingsCountMonth)
 , CAST(AVG(100. * C.CompanyNum / NULLIF(C.ActiveCompanyNum, 0)) AS DECIMAL(5,1)) AS Coverage
 , CAST(AVG(100. * C.CompanyNumMonth / NULLIF(C.ActiveCompanyNumMonth, 0)) AS DECIMAL(5,1)) AS CoverageMonth
 , AVG(C.ActiveCompanyNum)
 , AVG(C.ActiveCompanyNumMonth)
 , CAST(AVG(CL.AvgLoyalty * 100) AS DECIMAL(5,1)) AS AvgLoyalty
 , AVG(CL.LoyaltyCompanyNum)
 , CAST(AVG(UT.UnqTarget * 100) AS DECIMAL(5,1)) AS UnqTarget
 , AVG(UT.UnqCompanyNum)
 , AVG(UT.UnqVacancyNum)
 , AVG(C.CompanyNumPaid)
FROM C
 LEFT JOIN C_Loyalty CL ON C.ManagerEmail = CL.ManagerEmail
 LEFT JOIN C_UnqTarget UT ON C.ManagerEmail = UT.ManagerEmail;
