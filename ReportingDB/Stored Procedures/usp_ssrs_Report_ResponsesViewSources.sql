CREATE PROCEDURE [dbo].[usp_ssrs_Report_ResponsesViewSources]

AS


DECLARE @EndDate DATE = CAST(DATEADD(DAY, 1 - DATEPART(DAY, GETDATE()), GETDATE()) AS DATE);
DECLARE @StartDate DATE = DATEADD(MONTH, -6, @EndDate);

IF OBJECT_ID('tempdb..#ResponsesViewed','U') IS NOT NULL DROP TABLE #ResponsesViewed;

CREATE TABLE #ResponsesViewed
	(FullDate DATE, ResponseViewSource VARCHAR(8));

INSERT INTO #ResponsesViewed
SELECT Reporting.dbo.fnGetDatePart(AddDate) AS FullDate
 , CASE 
    WHEN VATV.IsViewedFromLetter = 1 THEN 'E-mail'
	ELSE 'Notebook'
   END AS ResponseViewSource
FROM Analytics.dbo.VacancyApplyToVacancy VATV
WHERE VATV.AddDate BETWEEN @StartDate AND @EndDate
 AND VATV.ViewedDate IS NOT NULL
 
UNION ALL

SELECT Reporting.dbo.fnGetDatePart(RTV.AddDate) AS FullDate
 , CASE 
    WHEN RTV.IsViewedFromLetter = 1 THEN 'E-mail'
	ELSE 'Notebook'
   END AS ResponseViewSource
FROM Analytics.dbo.ResumeToVacancy RTV
WHERE RTV.AddDate BETWEEN @StartDate AND @EndDate
 AND RTV.ViewedDate IS NOT NULL;

SELECT D.YearNum, D.MonthNameEng, D.MonthNum, RV.ResponseViewSource, COUNT(*) AS CntResponses
FROM #ResponsesViewed RV
 JOIN Reporting.dbo.DimDate D ON RV.FullDate = D.FullDate
GROUP BY D.YearNum, D.MonthNameEng, D.MonthNum, RV.ResponseViewSource
ORDER BY D.YearNum, D.MonthNum, RV.ResponseViewSource;

DROP TABLE #ResponsesViewed;