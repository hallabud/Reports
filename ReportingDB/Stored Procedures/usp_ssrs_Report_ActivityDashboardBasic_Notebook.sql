
CREATE PROCEDURE [dbo].[usp_ssrs_Report_ActivityDashboardBasic_Notebook] (@NotebookID INT)

AS

DECLARE @TodayDate DATETIME = dbo.fnGetDatePart(GETDATE());
DECLARE @StartDate DATETIME = DATEADD(DAY, 1 - DAY(DATEADD(MONTH, -6, @TodayDate)), DATEADD(MONTH, -6, @TodayDate));

DECLARE @Responses TABLE (FullDate DATETIME, IsViewed BIT, RespNum INT);
DECLARE @ResponsesViewSources TABLE (FullDate DATETIME, Source VARCHAR(10), RespNum INT);


INSERT INTO @Responses
SELECT ResponseDate, IsViewed, COUNT(*)
FROM
	(
	SELECT 
	   dbo.fnGetDatePart(VATV.AddDate) AS ResponseDate
	 , CASE WHEN ViewedDate IS NOT NULL THEN 1 ELSE 0 END AS IsViewed
	 , VATV.ID
	FROM Analytics.dbo.VacancyApplyToVacancy VATV 
	WHERE VATV.NotebookID = @NotebookID
	 AND VATV.AddDate BETWEEN @StartDate AND @TodayDate

	UNION ALL

	SELECT 
	   dbo.fnGetDatePart(RTV.AddDate) AS ResponseDate
	 , CASE WHEN ViewedDate IS NOT NULL THEN 1 ELSE 0 END AS IsViewed
	 , RTV.ID
	FROM Analytics.dbo.ResumeToVacancy RTV 
	WHERE RTV.NotebookID = @NotebookID
	 AND RTV.AddDate BETWEEN @StartDate AND @TodayDate
	) Responses
GROUP BY ResponseDate, IsViewed;

INSERT INTO @ResponsesViewSources
SELECT ResponseDate, Source, COUNT(*)
FROM
	(
	SELECT 
	   dbo.fnGetDatePart(VATV.ViewedDate) AS ResponseDate
	 , CASE WHEN IsViewedFromLetter = 1 THEN 'Почта' ELSE 'Блокнот' END AS Source
	 , VATV.ID
	FROM Analytics.dbo.VacancyApplyToVacancy VATV 
	WHERE VATV.NotebookID = @NotebookID
	 AND VATV.ViewedDate BETWEEN @StartDate AND @TodayDate

	UNION ALL

	SELECT 
	   dbo.fnGetDatePart(RTV.ViewedDate) AS ResponseDate
	 , CASE WHEN IsViewedFromLetter = 1 THEN 'Почта' ELSE 'Блокнот' END AS Source
	 , RTV.ID
	FROM Analytics.dbo.ResumeToVacancy RTV 
	WHERE RTV.NotebookID = @NotebookID
	 AND RTV.ViewedDate BETWEEN @StartDate AND @TodayDate
	) Responses
GROUP BY ResponseDate, Source;

SELECT 
   DC.NotebookId
 , DC.CompanyName
 , DC.VacancyDiffGroup
 , DC.IndexAttraction
 , DD.FullDate
 , DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.WeekNum
 , DD.WeekName
 , DD.DayNum
 , DD.WeekDayNum
 , (SELECT WorkVacancyNum FROM dbo.FactCompanyStatuses WHERE Date_key = DD.Date_key AND Company_key = DC.Company_key) AS WorkVacancyNum
 , (SELECT VacancyNum FROM dbo.FactCompanyStatuses WHERE Date_key = DD.Date_key AND Company_key = DC.Company_key) AS RabotaVacancyNum
 , ISNULL((SELECT RespNum FROM @Responses WHERE FullDate = DD.FullDate AND IsViewed = 1),0) AS ResponsesViewed
 , ISNULL((SELECT RespNum FROM @Responses WHERE FullDate = DD.FullDate AND IsViewed = 0),0) AS ResponsesNotViewed
 , ISNULL((SELECT RespNum FROM @ResponsesViewSources WHERE FullDate = DD.FullDate AND Source = 'Почта'),0) AS ResponsesViewedMail
 , ISNULL((SELECT RespNum FROM @ResponsesViewSources WHERE FullDate = DD.FullDate AND Source = 'Блокнот'),0) AS ResponsesViewedNotebook
FROM dbo.DimCompany DC
 JOIN dbo.DimDate DD ON DD.FullDate BETWEEN @StartDate AND @TodayDate
WHERE DC.NotebookId = @NotebookID;

