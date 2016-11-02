
CREATE PROCEDURE [dbo].[usp_ssrs_Report_SalesDepartmentManagementMetrics_AvgVacancy]

AS

-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-08-09
-- Description:	Процедура возвращает средне-недельное кол-во вакансий на работа.юэй и ворк.юэй за
--				отчетный период
-- ======================================================================================================


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

SELECT DISTINCT MM.YearNum, MM.WeekNum, MM.WeekName, Rabota_AvgVacancyCnt, Work_AvgVacancyCnt
FROM Reporting.dbo.AggrManagementMetrics MM
 JOIN Reporting.dbo.DimDate DD ON MM.YearNum = DD.YearNum AND MM.WeekNum = DD.WeekNum
WHERE DD.Date_key BETWEEN @ReportPeriodStartDateKey AND @ReportPeriodEndDateKey