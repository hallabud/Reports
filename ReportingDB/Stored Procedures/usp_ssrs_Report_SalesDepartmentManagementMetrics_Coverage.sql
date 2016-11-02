CREATE PROCEDURE [dbo].[usp_ssrs_Report_SalesDepartmentManagementMetrics_Coverage]

AS

-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-08-10
-- Description:	Процедура возвращает кол-во компаний, закрепленных за менеджерами работа.юэй, кол-во 
--				компаний с которыми был контакт в разрезе времени, менеджеров, тимлидов ...
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

DECLARE @Portfolio TABLE (ManagerID INT, ManagerEmail VARCHAR(100), TeamLeadID INT, TeamLeadName VARCHAR(100), NotebookID INT);
DECLARE @WeeksList TABLE (YearNum INT, WeekNum INT, WeekName VARCHAR(20), LastWeekDateMinusMonth DATETIME, LastWeekDate DATETIME);

-- список недель в отчетном периоде
INSERT INTO @WeeksList
SELECT DISTINCT YearNum, WeekNum, WeekName, DATEADD(MONTH, -1, LastWeekDate), LastWeekDate
FROM Reporting.dbo.DimDate
WHERE Date_key BETWEEN @ReportPeriodStartDateKey AND @ReportPeriodEndDateKey;

-- список компаний закрепленных за менеджерами продаж
INSERT INTO @Portfolio
SELECT M.Id AS ManagerID, MMB.Email, COALESCE(M.TeamLead_ManagerID, M.Id) AS TeamLeadID, COALESCE(TL.Name, M.Name) AS TeamLeadName, NotebookID
FROM Analytics.dbo.NotebookCompany NC
 JOIN Analytics.dbo.Manager M ON NC.ManagerId = M.Id
 JOIN Analytics.dbo.aspnet_Membership MMB ON M.aspnet_UserUIN = MMB.UserId
 LEFT JOIN Analytics.dbo.Manager TL ON M.TeamLead_ManagerID = TL.Id
WHERE NOT EXISTS (SELECT * FROM Analytics.dbo.NotebookCompanyMerged WHERE SourceNotebookID = NC.NotebookId) 
 AND M.DepartmentID IN (2,3,4)
 AND M.IsForTesting = 0
 AND M.IsReportExcluding = 0
 AND (M.TeamLead_ManagerID IS NOT NULL OR EXISTS (SELECT * FROM Analytics.dbo.Manager WHERE TeamLead_ManagerID = M.Id));
 
SELECT YearNum, WeekNum, WeekName, ManagerID, ManagerEmail, TeamLeadID, TeamLeadName/*, P.NotebookID, A.NotebookID*/, COUNT(DISTINCT P.NotebookID) AS PortfolioNotebooksCnt,  COUNT(DISTINCT A.NotebookID) AS ContactedNotebooksCnt
FROM @Portfolio P
 CROSS JOIN @WeeksList W
 LEFT JOIN Analytics.dbo.CRM_Action A ON P.NotebookID = A.NotebookID AND A.CompleteDate BETWEEN LastWeekDateMinusMonth AND LastWeekDate + 1 AND A.TypeID NOT IN (6,8,9) AND A.StateID = 2
GROUP BY YearNum, WeekNum, WeekName, ManagerID, ManagerEmail, TeamLeadID, TeamLeadName
ORDER BY ManagerID, YearNum, WeekNum;
