CREATE PROCEDURE dbo.usp_ssrs_Report_ResponsesByAge

AS

IF OBJECT_ID('tempdb..#Responses','U') IS NOT NULL DROP TABLE #Responses;
IF OBJECT_ID('tempdb..#FirstResponses','U') IS NOT NULL DROP TABLE #FirstResponses;

CREATE TABLE #Responses (Email varchar(100), AddDate datetime);
CREATE TABLE #FirstResponses (Email varchar(100) PRIMARY KEY, AddDate datetime);

INSERT INTO #Responses
SELECT VA.EMail, VATV.AddDate
FROM Analytics.dbo.VacancyApplyToVacancy VATV
 JOIN Analytics.dbo.VacancyApplyCVs VACV ON VATV.VacancyApplyCVsID = VACV.ID
 JOIN Analytics.dbo.VacancyApply VA ON VACV.VacancyApplyID = VA.ID

UNION ALL

SELECT R.Email, RTV.AddDate
FROM Analytics.dbo.ResumeToVacancy RTV
 JOIN Analytics.dbo.ResumeCVs RCV ON RTV.ResumeCVsID = RCV.ID
 JOIN Analytics.dbo.Resume R ON RCV.ResumeID = R.Id

INSERT INTO #FirstResponses
SELECT Email, MIN(AddDate) FROM #Responses GROUP BY Email;

SELECT YEAR(R.AddDate) AS YearNum, MONTH(R.AddDate) AS MonthNum, DATENAME(MONTH, R.AddDate) AS MonthNameEng
 , CASE 
    WHEN DATEDIFF(MONTH, FR.AddDate, R.AddDate) = 0 THEN 'this month'
	WHEN DATEDIFF(MONTH, FR.AddDate, R.AddDate) BETWEEN 1 AND 6 THEN CAST(DATEDIFF(MONTH, FR.AddDate, R.AddDate) AS varchar) + ' months ago'
	WHEN DATEDIFF(MONTH, FR.AddDate, R.AddDate) BETWEEN 6 AND 12 THEN '6-12 month ago'
	WHEN DATEDIFF(MONTH, FR.AddDate, R.AddDate) BETWEEN 12 AND 24 THEN '12-24 month ago'
	ELSE '24 or more month ago'
   END AS Age
 , COUNT(DISTINCT R.Email) AS EmailNum
 , COUNT(*) AS RespNum
FROM #Responses R
 JOIN #FirstResponses FR ON R.Email = FR.Email
WHERE R.AddDate >= '2014-01-01'
GROUP BY YEAR(R.AddDate), MONTH(R.AddDate), DATENAME(MONTH, R.AddDate)
 , CASE 
    WHEN DATEDIFF(MONTH, FR.AddDate, R.AddDate) = 0 THEN 'this month'
	WHEN DATEDIFF(MONTH, FR.AddDate, R.AddDate) BETWEEN 1 AND 6 THEN CAST(DATEDIFF(MONTH, FR.AddDate, R.AddDate) AS varchar) + ' months ago'
	WHEN DATEDIFF(MONTH, FR.AddDate, R.AddDate) BETWEEN 6 AND 12 THEN '6-12 month ago'
	WHEN DATEDIFF(MONTH, FR.AddDate, R.AddDate) BETWEEN 12 AND 24 THEN '12-24 month ago'
	ELSE '24 or more month ago'
   END
ORDER BY YearNum, MonthNum, Age;

DROP TABLE #Responses;
DROP TABLE #FirstResponses;