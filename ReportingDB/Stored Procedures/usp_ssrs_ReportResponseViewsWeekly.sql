
CREATE PROCEDURE [dbo].[usp_ssrs_ReportResponseViewsWeekly]
 (@StartDate DATETIME, @EndDate DATETIME)

AS

DECLARE @FirstApplyToShowDate DATETIME;
SET @FirstApplyToShowDate = '2013-06-03';

-- впихиваем в СТЕ все отклики (аттачем и профрезюме) без учета старых (если был прислан повторный)
WITH CTE_Responses AS
 (
SELECT
   dbo.fnGetDatePart(AddDate) AS ResponseDate
 , CASE 
    WHEN ViewedDate IS NOT NULL OR IsRead = 1 OR IsViewedFromLetter = 1 THEN 'Просмотренный'
    ELSE 'Непросмотренный'
   END AS ViewState
 , 'Отклик вложенным файлом' AS ResponseSource
 , VATV.ID
FROM Analytics.dbo.VacancyApplyToVacancy VATV
WHERE AddDate BETWEEN @StartDate AND @EndDate + 1

UNION ALL

SELECT 
   dbo.fnGetDatePart(AddDate) AS ResponseDate
 , CASE 
    WHEN ViewedDate IS NOT NULL OR IsRead = 1 OR IsViewedFromLetter = 1 THEN 'Просмотренный'
    ELSE 'Непросмотренный'
   END AS ViewState
 , 'Отклик профессиональным резюме' AS ResponseSource
 , RTV.ID
FROM Analytics.dbo.ResumeToVacancy RTV
WHERE AddDate BETWEEN @StartDate AND @EndDate + 1
 )

SELECT 
   DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.WeekNum
 , DD.WeekName
 , CR.ViewState
 , COUNT(*) AS ResponsesNum
FROM CTE_Responses CR
 JOIN Reporting.dbo.DimDate DD ON CR.ResponseDate = DD.FullDate
GROUP BY 
   DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.WeekNum
 , DD.WeekName
 , CR.ViewState;