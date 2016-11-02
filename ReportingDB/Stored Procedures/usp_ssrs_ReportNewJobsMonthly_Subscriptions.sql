
CREATE PROCEDURE [dbo].[usp_ssrs_ReportNewJobsMonthly_Subscriptions]

AS

SET DATEFIRST 1;

WITH NewJobsBySubscription AS 
-- группируем подписки по принципу 1 подписка - сумма новых вакансий в группах группирования
 (
SELECT 
   DATEPART(YEAR,Date) AS 'AlertYear'
 , DATEPART(MONTH,Date) AS 'AlertMonthNum'
 , DATENAME(MONTH,Date) AS 'AlertMonth'
 , SubscribeCompetitorID
 , SUM(ISNULL(NewVacancyCount,0)) AS SumNewVacancyCount
FROM Statistic.dbo.VacancySubscription_History VSH
 WHERE NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor 
					WHERE SourceType IN (2,7) AND Id = VSH.SubscribeCompetitorId)
GROUP BY DATEPART(YEAR,Date)
 , DATEPART(MONTH,Date)
 , DATENAME(MONTH,Date)
 , SubscribeCompetitorID
 )
, SubscriptionsByNewJobs AS
-- разбиваем на группы в зависимости от кол-во новых вакансий
 (
SELECT 
   AlertYear
 , AlertMonthNum
 , AlertMonth
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
 , AlertMonthNum
 , AlertMonth
 , NewVacancyCount
 , COUNT(SubscribeCompetitorID) AS AlertsCount
FROM SubscriptionsByNewJobs
GROUP BY 
   AlertYear
 , AlertMonthNum
 , AlertMonth
 , NewVacancyCount;
 