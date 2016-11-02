CREATE PROCEDURE [dbo].[usp_ssrs_Report_SalesDepartmentManagementMetrics_Revenue]

AS

-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-07-21
-- Description:	Процедура возвращает суммы потребленного сервиса и кол-ва блокнотов, потреблявших этот 
--				сервис в разрезе недель, менеджеров, тимлидов
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Update date: 2016-08-09
-- Description:	Добавлен вывод имени-фамилии тимлида
-- ======================================================================================================

SET NOCOUNT ON;
-- первый день недели = понедельник
SET DATEFIRST 1;

-- временная таблица для данных по потреблению сервиса (Recognized Revenue)
IF OBJECT_ID('tempdb..#Revenue','U') IS NOT NULL DROP TABLE #Revenue;


-- отчетный период = 12 недель
-- конечная дата отчетного периода = последний день недели, предшествующей текущей дате.
DECLARE @ReportPeriodEndDate DATE = DATEADD(DAY, - DATEPART(WEEKDAY, GETDATE()), GETDATE());
-- начальная дата отчетного периода = первый день -12й недели 
DECLARE @ReportPeriodStartDate DATE = DATEADD(DAY, 1, DATEADD(WEEK, -12, @ReportPeriodEndDate));
-- идентификаторы начальной и конечной дат в календаре
DECLARE @ReportPeriodStartDateKey INT = (SELECT Date_key FROM Reporting.dbo.DimDate WHERE FullDate = @ReportPeriodStartDate);
DECLARE @ReportPeriodEndDateKey INT = (SELECT Date_key FROM Reporting.dbo.DimDate WHERE FullDate = @ReportPeriodEndDate);

-- потребление сервиса (Recognized Revenue)
SELECT DD.YearNum, DD.WeekName, DD.WeekNum, M.Id AS ManagerID, COALESCE(M.TeamLead_ManagerID, M.Id) AS TeamLeadID, COALESCE(TL.Name, M.Name) AS TeamLeadName, SUM(RecognizedRevenue) AS SumRR, COUNT(DISTINCT RRN.NotebookID) AS RevenueNotebookCount
INTO #Revenue
FROM Reporting.dbo.FactRecognizedRevenueNotebook RRN
 JOIN Reporting.dbo.DimDate DD ON RRN.Date_key = DD.Date_key
 JOIN Analytics.dbo.NotebookCompany NC ON RRN.NotebookID = NC.NotebookId
 JOIN Analytics.dbo.Manager M ON NC.ManagerId = M.Id
 LEFT JOIN Analytics.dbo.Manager TL ON M.TeamLead_ManagerID = TL.Id
WHERE RRN.Date_key BETWEEN @ReportPeriodStartDateKey AND @ReportPeriodEndDateKey
 AND M.IsForTesting = 0
GROUP BY DD.YearNum, DD.WeekName, DD.WeekNum, M.Id, COALESCE(M.TeamLead_ManagerID, M.Id), COALESCE(TL.Name, M.Name);

SELECT YearNum, WeekName, WeekNum, ManagerID, TeamLeadID, TeamLeadName, SumRR, RevenueNotebookCount 
FROM #Revenue
