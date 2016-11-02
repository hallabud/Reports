CREATE PROCEDURE dbo.usp_ssrs_Report_SalesDepartmentManagementMetrics_Unique

AS

-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-08-09
-- Description:	Процедура возвращает кол-ва вакансий на работа.юэй, кол-во вакансий на ворк.юэй, которых
--				нет на работа.юэй, а также средние кол-ва этих же показателей за последние 30 дней, 
--				в разрезе времени, менеджеров, тимлидов
-- ======================================================================================================

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET NOCOUNT ON;
-- первый день недели = понедельник
SET DATEFIRST 1;

-- отчетный период = 12 недель
-- конечная дата отчетного периода = последний день недели, предшествующей текущей дате.
DECLARE @ReportPeriodEndDate DATE = DATEADD(DAY, - DATEPART(WEEKDAY, GETDATE()), GETDATE());
-- начальная дата отчетного периода = первый день -12й недели 
DECLARE @ReportPeriodStartDate DATE = DATEADD(DAY, 1, DATEADD(WEEK, -12, @ReportPeriodEndDate));
-- идентификаторы начальной и конечной дат в календаре
DECLARE @ReportPeriodStartDateKey INT = (SELECT Date_key FROM Reporting.dbo.DimDate WHERE FullDate = @ReportPeriodStartDate);
DECLARE @ReportPeriodEndDateKey INT = (SELECT Date_key FROM Reporting.dbo.DimDate WHERE FullDate = @ReportPeriodEndDate);
-- идентификатор "начальная дата - 30 дней" (для расчета среднего % уникальных вакансий и охвата за последние 30 дней)
DECLARE @StartDateKey INT = @ReportPeriodStartDateKey - 30;

-- временная таблица для расчета среднего кол-ва вакансий за последние 30 дней (используется для расчета среднего % уникальных вакансий за последние 30 дней)

IF OBJECT_ID('tempdb..#T','U') IS NOT NULL DROP TABLE #T;

SELECT FCS.Date_key
 , DD.YearNum, DD.WeekNum, DD.WeekName, DD.FullDate
 , M.Id AS ManagerID
 , COALESCE(TL.Id, M.Id) AS TeamLeadID
 , COALESCE(TL.Name, M.Name) AS TeamLeadName
 , SUM(FCS.VacancyNum) AS SumVacancyNum
 , SUM(FCS.UnqWorkVacancyNum) AS SumUnqWorkVacancyNum
 , AVG(SUM(FCS.VacancyNum)) OVER (PARTITION BY M.Id ORDER BY FCS.Date_key ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) AS AvgVacancyNum30Days
 , AVG(SUM(FCS.UnqWorkVacancyNum)) OVER (PARTITION BY M.Id ORDER BY FCS.Date_key ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) AS AvgUnqWorkVacancyNum30Days
INTO #T
FROM Reporting.dbo.FactCompanyStatuses FCS
 JOIN Reporting.dbo.DimCompany DC ON FCS.Company_key = DC.Company_Key
 JOIN Reporting.dbo.DimDate DD ON FCS.Date_key = DD.Date_key 
 JOIN Analytics.dbo.aspnet_Membership MMB ON DC.ManagerEmail = MMB.Email
 JOIN Analytics.dbo.Manager M ON MMB.UserId = M.aspnet_UserUIN
 LEFT JOIN Analytics.dbo.Manager TL ON M.TeamLead_ManagerID = TL.Id
WHERE FCS.Date_key BETWEEN @StartDateKey AND @ReportPeriodEndDateKey
 AND DC.WorkConnectionGroup = 'Привязанные компании'
 AND FCS.VacancyDiffGroup <> 'R = W = 0'
GROUP BY FCS.Date_key
 , DD.YearNum, DD.WeekNum, DD.WeekName, DD.FullDate
 , M.Id
 , COALESCE(TL.Id, M.Id)
 , COALESCE(TL.Name, M.Name);

SELECT * 
FROM #T T
WHERE Date_key BETWEEN @ReportPeriodStartDateKey AND @ReportPeriodEndDateKey
 AND EXISTS (SELECT * FROM Analytics.dbo.Manager WHERE TeamLead_ManagerID = T.ManagerID OR (Id = T.ManagerID AND TeamLead_ManagerID IS NOT NULL)) 
ORDER BY ManagerID, FullDate;