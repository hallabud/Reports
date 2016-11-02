
CREATE PROCEDURE [dbo].[usp_ssrs_ReportDashboard]
 (@part VARCHAR(100))

AS

DECLARE @Today DATETIME; SET @Today = dbo.fnGetDatePart(GETDATE());
DECLARE @Yesterday DATETIME; SET @Yesterday = DATEADD(DAY,-1,@Today);
DECLARE @BeforeYesterday DATETIME; SET @BeforeYesterday = DATEADD(DAY,-2,@Today);
DECLARE @WeekAgo DATETIME; SET @WeekAgo = DATEADD(WEEK,-1,@Today);
DECLARE @PreviousWeekFirstDate DATETIME; SELECT @PreviousWeekFirstDate = MIN(FullDate) FROM dbo.DimDate WHERE YearNum = DATEPART(YEAR,@WeekAgo) AND WeekNum = DATEPART(WEEK,@WeekAgo);
DECLARE @PreviousWeekLastDate DATETIME; SET @PreviousWeekLastDate = DATEADD(DAY,7,@PreviousWeekFirstDate);
DECLARE @2WeeksAgoFirstDate DATETIME; SET @2WeeksAgoFirstDate = DATEADD(WEEK,-1,@PreviousWeekFirstDate);
DECLARE @2WeeksAgoLastDate DATETIME; SET @2WeeksAgoLastDate = DATEADD(WEEK,-1,@PreviousWeekLastDate);

IF OBJECT_ID('tempdb.dbo.#Dashboard_Vacancy','U') IS NOT NULL DROP TABLE #Dashboard_Vacancy;
IF OBJECT_ID('tempdb..#Pivoted_Vacancy','U') IS NOT NULL DROP TABLE #Pivoted_Vacancy;
IF OBJECT_ID('tempdb..#Final_Vacancy','U') IS NOT NULL DROP TABLE #Final_Vacancy;
IF OBJECT_ID('tempdb.dbo.#Dashboard_Company','U') IS NOT NULL DROP TABLE #Dashboard_Company;
IF OBJECT_ID('tempdb..#Pivoted_Company','U') IS NOT NULL DROP TABLE #Pivoted_Company;
IF OBJECT_ID('tempdb..#Final_Company','U') IS NOT NULL DROP TABLE #Final_Company;
IF OBJECT_ID('tempdb.dbo.#Dashboard_Company2','U') IS NOT NULL DROP TABLE #Dashboard_Company2;
IF OBJECT_ID('tempdb..#Pivoted_Company2','U') IS NOT NULL DROP TABLE #Pivoted_Company2;
IF OBJECT_ID('tempdb..#Final_Company2','U') IS NOT NULL DROP TABLE #Final_Company2;
IF OBJECT_ID('tempdb..#Final_JA','U') IS NOT NULL DROP TABLE #Final_JA;
IF OBJECT_ID('tempdb..#Dashboard_Resume','U') IS NOT NULL DROP TABLE #Dashboard_Resume;
IF OBJECT_ID('tempdb..#Pivoted_Resume','U') IS NOT NULL DROP TABLE #Pivoted_Resume;
IF OBJECT_ID('tempdb..#Final_Resume','U') IS NOT NULL DROP TABLE #Final_Resume;

/******************************************************************************/
/*********************** Дешборд по вакансиям *********************************/
/******************************************************************************/
IF @part = 'Vacancy'
BEGIN

	SELECT 'всего:' AS 'Period', 'rabota.ua' AS 'Source', VacancyCount AS 'Amount'
	INTO #Dashboard_Vacancy
	FROM SRV16.RabotaUA2.dbo.Spider2VacancyCountByCity S2V
	WHERE S2V.CityID = 0 AND S2V.Source = 0
	 AND S2V.Date = (SELECT MAX(Date) FROM SRV16.RabotaUA2.dbo.Spider2VacancyCountByCity)
	UNION ALL
	SELECT 'за прошлую неделю:', 'rabota.ua', COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.Vacancy V
	WHERE V.AddDate BETWEEN @PreviousWeekFirstDate AND @PreviousWeekLastDate
	 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 1)
	 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 2)
	 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.VacancyPublishHistory WHERE VacancyId = V.Id)
	UNION ALL
	SELECT 'за позапрошлую неделю:', 'rabota.ua', COUNT(*)
	FROM SRV16.RabotaUA2.dbo.Vacancy V
	WHERE V.AddDate BETWEEN @2WeeksAgoFirstDate AND @2WeeksAgoLastDate
	 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 1)
	 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 2)
	 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.VacancyPublishHistory WHERE VacancyId = V.Id)
	UNION ALL
	SELECT 'всего:', 'work.ua', VacancyCount
	FROM SRV16.RabotaUA2.dbo.Spider2VacancyCountByCity S2V
	WHERE S2V.CityID = 0 AND S2V.Source = 1
	 AND S2V.Date = (SELECT MAX(Date) FROM SRV16.RabotaUA2.dbo.Spider2VacancyCountByCity)
	UNION ALL
	SELECT 'за прошлую неделю:', 'work.ua', Vacancy_New_Count_Weekly 
	FROM SRV16.RabotaUA2.dbo.SpiderCompany_WorkStat SCWS
	WHERE SCWS.Date = @PreviousWeekLastDate - 1
	UNION ALL
	SELECT 'за позапрошлую неделю:', 'work.ua', Vacancy_New_Count_Weekly 
	FROM SRV16.RabotaUA2.dbo.SpiderCompany_WorkStat SCWS
	WHERE SCWS.Date = @2WeeksAgoLastDate - 1;

	SELECT Period, [rabota.ua] AS 'rabota.ua', [work.ua] AS 'work.ua'
	INTO #Pivoted_Vacancy
	FROM 
	(SELECT * 
	FROM #Dashboard_Vacancy) p
	PIVOT 
	(
	SUM(Amount)
	FOR Source IN ([rabota.ua],[work.ua])
	) AS pvt

	SELECT * 
	INTO #Final_Vacancy
	FROM #Pivoted_Vacancy
	UNION ALL
	SELECT 
	   'изменение по сравнению с позапрошлой неделей, %'
	 , 100. * (SELECT [rabota.ua] FROM #Pivoted_Vacancy WHERE Period = 'за прошлую неделю:') / (SELECT NULLIF([rabota.ua],0) FROM #Pivoted_Vacancy WHERE Period = 'за позапрошлую неделю:') - 100
	 , 100. * (SELECT [work.ua] FROM #Pivoted_Vacancy WHERE Period = 'за прошлую неделю:') / (SELECT NULLIF([work.ua],0) FROM #Pivoted_Vacancy WHERE Period = 'за позапрошлую неделю:') - 100

END

/******************************************************************************/
/***************** Дешборд по компаниям с вакансиями **************************/
/******************************************************************************/
IF @part = 'Company'
BEGIN

	SELECT 
	   'всего:' AS 'Period'
	 , 'rabota.ua' AS 'Source'
	 , COUNT(*) AS 'Amount'
	INTO #Dashboard_Company
	FROM SRV16.RabotaUA2.dbo.NotebookCompany NC WITH (NOLOCK)
	 JOIN SRV16.RabotaUA2.dbo.Notebook N WITH (NOLOCK) ON NC.NotebookID = N.Id
	WHERE /*NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompanyMerged NCM WHERE NCM.SourceNotebookId = NC.NotebookId)
	 AND*/ EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent WHERE NotebookId = NC.NotebookID)
	 AND N.NotebookStateID IN (5,7)
	UNION ALL
	SELECT 
	   'за прошлую неделю:' AS 'Period'
	 , 'rabota.ua' AS 'Source'
	 , COUNT(*)
	FROM SRV16.RabotaUA2.dbo.NotebookCompany NC
	 JOIN SRV16.RabotaUA2.dbo.Notebook N WITH (NOLOCK) ON NC.NotebookID = N.Id
	WHERE NC.AddDate BETWEEN @PreviousWeekFirstDate AND @PreviousWeekLastDate
	 -- AND NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompanyMerged NCM WHERE NCM.SourceNotebookId = NC.NotebookId)
	 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent WHERE NotebookId = NC.NotebookID AND AddDate BETWEEN @PreviousWeekFirstDate AND @PreviousWeekLastDate)
	 AND N.NotebookStateID IN (5,7)
	UNION ALL
	SELECT 
	   'за позапрошлую неделю:' AS 'Period'
	 , 'rabota.ua' AS 'Source'
	 , COUNT(*)
	FROM SRV16.RabotaUA2.dbo.NotebookCompany NC
	 JOIN SRV16.RabotaUA2.dbo.Notebook N WITH (NOLOCK) ON NC.NotebookID = N.Id
	WHERE NC.AddDate BETWEEN @2WeeksAgoFirstDate AND @2WeeksAgoLastDate
	 -- AND NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompanyMerged NCM WHERE NCM.SourceNotebookId = NC.NotebookId)
	 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent WHERE NotebookId = NC.NotebookID AND AddDate BETWEEN @2WeeksAgoFirstDate AND @2WeeksAgoLastDate)
	 AND N.NotebookStateID IN (5,7)
	UNION ALL
	SELECT 
	   'всего:' AS 'Period'
	 , 'work.ua' AS 'Source'
	 , COUNT(DISTINCT ISNULL(NotebookID, CompanyId)) AS 'Amount'
	FROM SRV16.RabotaUA2.dbo.SpiderCompany SC
	WHERE Source = 1
	UNION ALL
	SELECT 
	   'за прошлую неделю:' AS 'Period'
	 , 'work.ua' AS 'Source'
	 , COUNT(DISTINCT ISNULL(NotebookID, CompanyId)) AS 'Amount'
	FROM SRV16.RabotaUA2.dbo.SpiderCompany SC
	WHERE AddDate BETWEEN @PreviousWeekFirstDate AND @PreviousWeekLastDate
	 AND Source = 1
	UNION ALL
	SELECT 
	   'за позапрошлую неделю:' AS 'Period'
	 , 'work.ua' AS 'Source'
	 , COUNT(DISTINCT ISNULL(NotebookID, CompanyId)) AS 'Amount'
	FROM SRV16.RabotaUA2.dbo.SpiderCompany SC
	WHERE AddDate BETWEEN @2WeeksAgoFirstDate AND @2WeeksAgoLastDate
	 AND Source = 1;

	SELECT Period, [rabota.ua] AS 'rabota.ua', [work.ua] AS 'work.ua'
	INTO #Pivoted_Company
	FROM 
	(SELECT * 
	FROM #Dashboard_Company) p
	PIVOT 
	(
	SUM(Amount)
	FOR Source IN ([rabota.ua],[work.ua])
	) AS pvt

	SELECT * 
	INTO #Final_Company
	FROM #Pivoted_Company
	UNION ALL
	SELECT 
	   'изменение по сравнению с позапрошлой неделей, %'
	 , 100. * (SELECT [rabota.ua] FROM #Pivoted_Company WHERE Period = 'за прошлую неделю:') / (SELECT NULLIF([rabota.ua],0) FROM #Pivoted_Company WHERE Period = 'за позапрошлую неделю:') - 100
	 , 100. * (SELECT [work.ua] FROM #Pivoted_Company WHERE Period = 'за прошлую неделю:') / (SELECT NULLIF([work.ua],0) FROM #Pivoted_Company WHERE Period = 'за позапрошлую неделю:') - 100;

END

/******************************************************************************/
/********************* Дешборд по компаниям (всего) ***************************/
/******************************************************************************/
IF @part = 'Company2'
BEGIN

	SELECT 
	   'всего:' AS 'Period'
	 , 'rabota.ua' AS 'Source'
	 , COUNT(*) AS 'Amount'
	INTO #Dashboard_Company2
	FROM SRV16.RabotaUA2.dbo.NotebookCompany NC
	-- WHERE NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompanyMerged NCM WHERE NCM.SourceNotebookId = NC.NotebookId)
	UNION ALL
	SELECT 
	   'за прошлую неделю:' AS 'Period'
	 , 'rabota.ua' AS 'Source'
	 , COUNT(*)
	FROM SRV16.RabotaUA2.dbo.NotebookCompany NC
	WHERE NC.AddDate BETWEEN @PreviousWeekFirstDate AND @PreviousWeekLastDate
	 -- AND NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompanyMerged NCM WHERE NCM.SourceNotebookId = NC.NotebookId)
	UNION ALL
	SELECT 
	   'за позапрошлую неделю:' AS 'Period'
	 , 'rabota.ua' AS 'Source'
	 , COUNT(*)
	FROM SRV16.RabotaUA2.dbo.NotebookCompany NC
	WHERE NC.AddDate BETWEEN @2WeeksAgoFirstDate AND @2WeeksAgoLastDate
	 -- AND NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompanyMerged NCM WHERE NCM.SourceNotebookId = NC.NotebookId)
	UNION ALL
	SELECT 
	   'всего:' AS 'Period'
	 , 'work.ua' AS 'Source'
	 , MAX(CompanyID) - MIN(CompanyID) AS 'Amount'
	FROM SRV16.RabotaUA2.dbo.SpiderCompany SC
	WHERE Source = 1
	UNION ALL
	SELECT 
	   'за прошлую неделю:' AS 'Period'
	 , 'work.ua' AS 'Source'
	 , MAX(CompanyID) - (SELECT MAX(CompanyID) FROM Analytics.dbo.SpiderCompany WHERE Source = 1 AND AddDate BETWEEN @2WeeksAgoFirstDate AND @2WeeksAgoLastDate) AS 'Amount'
	FROM SRV16.RabotaUA2.dbo.SpiderCompany SC
	WHERE AddDate BETWEEN @PreviousWeekFirstDate AND @PreviousWeekLastDate
	 AND Source = 1
	UNION ALL
	SELECT 
	   'за позапрошлую неделю:' AS 'Period'
	 , 'work.ua' AS 'Source'
	 , MAX(CompanyID) - (SELECT MAX(CompanyID) FROM Analytics.dbo.SpiderCompany WHERE Source = 1 AND AddDate < @2WeeksAgoFirstDate) AS 'Amount'
	FROM SRV16.RabotaUA2.dbo.SpiderCompany SC
	WHERE AddDate BETWEEN @2WeeksAgoFirstDate AND @2WeeksAgoLastDate
	 AND Source = 1;

	SELECT Period, [rabota.ua] AS 'rabota.ua', [work.ua] AS 'work.ua'
	INTO #Pivoted_Company2
	FROM 
	(SELECT * 
	FROM #Dashboard_Company2) p
	PIVOT 
	(
	SUM(Amount)
	FOR Source IN ([rabota.ua],[work.ua])
	) AS pvt

	SELECT * 
	INTO #Final_Company2
	FROM #Pivoted_Company2
	UNION ALL
	SELECT 
	   'изменение по сравнению с позапрошлой неделей, %'
	 , 100. * (SELECT [rabota.ua] FROM #Pivoted_Company2 WHERE Period = 'за прошлую неделю:') / (SELECT NULLIF([rabota.ua],0) FROM #Pivoted_Company2 WHERE Period = 'за позапрошлую неделю:') - 100
	 , 100. * (SELECT [work.ua] FROM #Pivoted_Company2 WHERE Period = 'за прошлую неделю:') / (SELECT NULLIF([work.ua],0) FROM #Pivoted_Company2 WHERE Period = 'за позапрошлую неделю:') - 100;

END


/******************************************************************************/
/*********************** Дешборд по подпискам *********************************/
/******************************************************************************/
IF @part = 'JA'
BEGIN

	SELECT 
	   'всего:' AS Period
	 , COUNT(*) AS 'Subscriptions'
	INTO #Dashboard_JA
	FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor SC
	WHERE IsActive = 1
	UNION ALL
	SELECT 
	   'вчера:'
	 , COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor SC
	WHERE SC.AddDate BETWEEN @Yesterday AND @Today
	 AND IsActive = 1
	UNION ALL
	SELECT 
	   'позавчера:'
	 , COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor SC
	WHERE SC.AddDate BETWEEN @BeforeYesterday AND @Yesterday
	 AND IsActive = 1
	UNION ALL
	SELECT 
	   'за прошлую неделю:' AS 'Period'
	 , COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor SC
	WHERE SC.AddDate BETWEEN @PreviousWeekFirstDate AND @PreviousWeekLastDate
	 AND IsActive = 1
	UNION ALL
	SELECT 
	   'за позапрошлую неделю:' AS 'Period'
	 , COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor SC
	WHERE SC.AddDate BETWEEN @2WeeksAgoFirstDate AND @2WeeksAgoLastDate
	 AND IsActive = 1;

	SELECT * 
	INTO #Final_JA
	FROM #Dashboard_JA
	UNION ALL
	SELECT 
	   'изменение вчера/позавчера, %'
	 , 100. * (SELECT Subscriptions FROM #Dashboard_JA WHERE Period = 'вчера:') / (SELECT Subscriptions FROM #Dashboard_JA WHERE Period = 'позавчера:') - 100
	UNION ALL
	SELECT 
	   'изменение по сравнению с позапрошлой неделей, %'
	 , 100. * (SELECT Subscriptions FROM #Dashboard_JA WHERE Period = 'за прошлую неделю:') / (SELECT Subscriptions FROM #Dashboard_JA WHERE Period = 'за позапрошлую неделю:') - 100;

END

/******************************************************************************/
/*********************** Дешборд по резюме ************************************/
/******************************************************************************/
IF @part = 'Resume'
BEGIN

	SELECT 'за прошлую неделю:' AS Period, 'rabota.ua' AS Source, COUNT(*) AS Amount
	INTO #Dashboard_Resume
	FROM SRV16.RabotaUA2.dbo.Resume R
	WHERE R.AddDate BETWEEN @PreviousWeekFirstDate AND @PreviousWeekLastDate
	 AND R.State NOT IN (0,2,7)
	UNION ALL
	SELECT 'за позапрошлую неделю:', 'rabota.ua', COUNT(*)
	FROM SRV16.RabotaUA2.dbo.Resume R
	WHERE R.AddDate BETWEEN @2WeeksAgoFirstDate AND @2WeeksAgoLastDate
	 AND R.State NOT IN (0,2,7)
	UNION ALL
	SELECT 'за прошлую неделю:', 'work.ua', Resume_New_Count_Weekly 
	FROM SRV16.RabotaUA2.dbo.SpiderCompany_WorkStat SCWS
	WHERE SCWS.Date = @PreviousWeekLastDate - 1
	UNION ALL
	SELECT 'за позапрошлую неделю:', 'work.ua', Resume_New_Count_Weekly 
	FROM SRV16.RabotaUA2.dbo.SpiderCompany_WorkStat SCWS
	WHERE SCWS.Date = @2WeeksAgoLastDate - 1;

	SELECT Period, [rabota.ua] AS 'rabota.ua', [work.ua] AS 'work.ua'
	INTO #Pivoted_Resume
	FROM 
	(SELECT * 
	FROM #Dashboard_Resume) p
	PIVOT 
	(
	SUM(Amount)
	FOR Source IN ([rabota.ua],[work.ua])
	) AS pvt

	SELECT * 
	INTO #Final_Resume
	FROM #Pivoted_Resume
	UNION ALL
	SELECT 
	   'изменение по сравнению с позапрошлой неделей, %'
	 , 100. * (SELECT [rabota.ua] FROM #Pivoted_Resume WHERE Period = 'за прошлую неделю:') / (SELECT NULLIF([rabota.ua],0) FROM #Pivoted_Resume WHERE Period = 'за позапрошлую неделю:') - 100
	 , 100. * (SELECT [work.ua] FROM #Pivoted_Resume WHERE Period = 'за прошлую неделю:') / (SELECT NULLIF([work.ua],0) FROM #Pivoted_Resume WHERE Period = 'за позапрошлую неделю:') - 100

END



/******************************************************************************/
/*********************** Вывод ************************************************/
/******************************************************************************/

IF @part = 'Vacancy'
BEGIN
SELECT 
   * 
 , CASE 
    WHEN Period = 'изменение по сравнению с позапрошлой неделей, %' THEN ([rabota.ua] - [work.ua]) / 100.
	ELSE 1.0 * ([rabota.ua] - [work.ua]) / NULLIF(ABS(dbo.fnGetMinimumOf2Values([rabota.ua],[work.ua])),0)
   END AS 'Gap'
FROM #Final_Vacancy
ORDER BY CASE Period WHEN 'всего:' THEN 1 WHEN 'за прошлую неделю:' THEN 2 WHEN 'за позапрошлую неделю:' THEN 3 ELSE 4 END;
END;

IF @part = 'Company'
BEGIN
SELECT 
   * 
 , CASE 
    WHEN Period = 'изменение по сравнению с позапрошлой неделей, %' THEN ([rabota.ua] - [work.ua])/ 100.
    ELSE 1.0 * ([rabota.ua] - [work.ua]) / 
	CASE 
	 WHEN ABS(dbo.fnGetMinimumOf2Values([rabota.ua],[work.ua])) = 0 THEN ([rabota.ua] - [work.ua]) 
	 ELSE ABS(dbo.fnGetMinimumOf2Values([rabota.ua],[work.ua])) 
    END 
   END AS 'Gap'
FROM #Final_Company
ORDER BY CASE Period WHEN 'всего:' THEN 1 WHEN 'за прошлую неделю:' THEN 2 WHEN 'за позапрошлую неделю:' THEN 3 ELSE 4 END;
END

IF @part = 'Company2'
BEGIN
SELECT 
   * 
 , CASE 
    WHEN Period = 'изменение по сравнению с позапрошлой неделей, %' THEN ([rabota.ua] - [work.ua])/ 100.
    ELSE 1.0 * ([rabota.ua] - [work.ua]) / 
	CASE 
	 WHEN ABS(dbo.fnGetMinimumOf2Values([rabota.ua],[work.ua])) = 0 THEN ([rabota.ua] - [work.ua]) 
	 ELSE ABS(dbo.fnGetMinimumOf2Values([rabota.ua],[work.ua])) 
    END 
   END AS 'Gap'
FROM #Final_Company2
ORDER BY CASE Period WHEN 'всего:' THEN 1 WHEN 'за прошлую неделю:' THEN 2 WHEN 'за позапрошлую неделю:' THEN 3 ELSE 4 END;
END

IF @part = 'JA'
BEGIN
SELECT 
   * 
FROM #Final_JA
ORDER BY CASE Period WHEN 'всего:' THEN 1 WHEN 'вчера:' THEN 2 WHEN 'позавчера:' THEN 3 WHEN 'изменение вчера/позавчера, %' THEN 4 WHEN 'за прошлую неделю:' THEN 5 WHEN 'за позапрошлую неделю:' THEN 6  ELSE 9 END;
END

IF @part = 'Resume'
BEGIN
SELECT 
   * 
 , CASE 
    WHEN Period = 'изменение по сравнению с позапрошлой неделей, %' THEN ([rabota.ua] - [work.ua]) / 100.
	ELSE 1.0 * ([rabota.ua] - [work.ua]) / NULLIF(ABS(dbo.fnGetMinimumOf2Values([rabota.ua],[work.ua])),0)
   END AS 'Gap'
FROM #Final_Resume
ORDER BY CASE Period WHEN 'всего:' THEN 1 WHEN 'за прошлую неделю:' THEN 2 WHEN 'за позапрошлую неделю:' THEN 3 ELSE 4 END;
END;