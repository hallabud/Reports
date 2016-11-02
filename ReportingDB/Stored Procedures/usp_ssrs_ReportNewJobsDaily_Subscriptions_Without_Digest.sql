
CREATE PROCEDURE [dbo].[usp_ssrs_ReportNewJobsDaily_Subscriptions_Without_Digest]
 (@StartDate DATETIME, @EndDate DATETIME)

AS 

SET DATEFIRST 1;

WITH NewJobsBySubscription AS 
-- группируем подписки по принципу 1 подписка - сумма новых вакансий в группах группирования
 (
SELECT 
   DATEPART(YEAR,Date) AS 'AlertYear'
 , DATEPART(WEEK,Date) AS 'AlertWeekNum'
 , DATENAME(WEEKDAY,Date) AS 'AlertWeekDay'
 , Date AS 'AlertDateDT'
 , CONVERT(VARCHAR, Date, 104) AS 'AlertDate'
 , SubscribeCompetitorID
 , ISNULL(NewVacancyCount,0) AS SumNewVacancyCount
FROM Statistic.dbo.VacancySubscription_History VSH WITH (NOLOCK)
WHERE NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor WITH (NOLOCK)
					WHERE SourceType IN (2,7) AND Id = VSH.SubscribeCompetitorId)
 AND Date BETWEEN @StartDate AND @EndDate
 AND DATEPART(WEEKDAY,Date) <> 1
 )
, SubscriptionsByNewJobs AS
-- разбиваем на группы в зависимости от кол-во новых вакансий
 (
SELECT 
   AlertYear
 , AlertWeekNum
 , AlertWeekDay 
 , AlertDateDT
 , AlertDate
 , CASE 
    WHEN SumNewVacancyCount < 6 THEN CAST(SumNewVacancyCount AS VARCHAR)+' new jobs'
    WHEN SumNewVacancyCount BETWEEN 6 AND 8 THEN '6 - 8 new jobs'
    WHEN SumNewVacancyCount BETWEEN 9 AND 10 THEN '9 - 10 new jobs'
    ELSE 'more than 10 new jobs' END
   AS 'NewVacancyCount'
 , SubscribeCompetitorID
FROM NewJobsBySubscription
 )
SELECT 
   AlertYear
 , AlertWeekNum
 , AlertWeekDay 
 , AlertDateDT
 , AlertDate
 , NewVacancyCount
 , COUNT(SubscribeCompetitorID) AS AlertsCount
FROM SubscriptionsByNewJobs
GROUP BY 
   AlertYear
 , AlertWeekNum
 , AlertWeekDay 
 , AlertDateDT
 , AlertDate
 , NewVacancyCount;