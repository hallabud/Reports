CREATE PROCEDURE [dbo].[usp_ssrs_Report_WebsitePerformance] @StartDate DATETIME, @EndDate DATETIME

AS


SELECT 
   dbo.fnGetDatePart(Date) AS FullDate
 , NULL AS ServerName
 , CASE PageID
    WHEN 1 THEN 'Главная' 
	WHEN 2 THEN 'Результаты поиска вакансий'
	WHEN 3 THEN 'Страница вакансий'
	WHEN 4 THEN 'Страница вакансий компании'
	WHEN 5 THEN 'Результаты поиска резюме'
	WHEN 6 THEN 'Страница резюме'
   END AS Name
 , Time_Avg / 1000. AS Value
FROM SRV16.RabotaUA2.dbo.Monitor_SitePage WITH (NOLOCK)
WHERE Date BETWEEN @StartDate AND @EndDate + 1

UNION ALL

SELECT dbo.fnGetDatePart(AddDate), 'SRV16' AS ServerName, 'Сервис перегружен, кол-во ошибок' AS Name, COUNT(ID) AS Value
FROM SRV16.RabotaUA2.dbo.TempDB_LOG WITH (NOLOCK)
WHERE Type IN (1,2,3,4)
 AND AddDate BETWEEN @StartDate AND @EndDate + 1
GROUP BY dbo.fnGetDatePart(AddDate)

UNION ALL

SELECT dbo.fnGetDatePart(AddDate), 'SRV14' AS ServerName, 'Сервис перегружен, кол-во ошибок' AS Name, COUNT(ID) AS Value
FROM SRV14.RabotaUA2.dbo.TempDB_LOG WITH (NOLOCK)
WHERE Type IN (1,2,3,4)
 AND AddDate BETWEEN @StartDate AND @EndDate + 1
GROUP BY dbo.fnGetDatePart(AddDate)


UNION ALL

SELECT dbo.fnGetDatePart(PSA.ExecDate) AS FullDate, NULL AS ServerName, PL.Name AS Name, Avg(PSA.AvgTime) / 1000. AS Value
FROM SRV16.RabotaUA2.dbo.__ProcStatistic_Aggregator_Detail PSA WITH (NOLOCK)
	JOIN SRV16.RabotaUA2.dbo.__ProcList PL WITH (NOLOCK) ON PSA.ProcID = PL.ID
WHERE PSA.ProcID IN (17, 402, 1021, 399)
	AND ExecDate BETWEEN @StartDate AND @EndDate + 1
GROUP BY dbo.fnGetDatePart(PSA.ExecDate), PL.Name
;