
CREATE PROCEDURE [dbo].[usp_ssrs_ReportNewJobsWeekly_Subscriptions_Without_Digest]

AS

SET DATEFIRST 1;

WITH NewJobsBySubscription AS 
-- группируем подписки по принципу 1 подписка - сумма новых вакансий в группах группирования
 (
SELECT 
   D.YearNum AS 'AlertYear'
 , D.WeekName AS 'AlertWeekName'
 , D.WeekNum AS 'AlertWeekNum'
 , SubscribeCompetitorID
 , SUM(ISNULL(NewVacancyCount,0)) AS SumNewVacancyCount
FROM Statistic.dbo.VacancySubscription_History VSH
 JOIN Reporting.dbo.DimDate D
  ON VSH.Date = D.FullDate
WHERE NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor 
				  WHERE SourceType IN (2,7) AND Id = VSH.SubscribeCompetitorId)
 AND D.WeekDayNum <> 1
GROUP BY 
   D.YearNum
 , D.WeekName
 , D.WeekNum
 , SubscribeCompetitorID
 )
, SubscriptionsByNewJobs AS
-- разбиваем на группы в зависимости от кол-во новых вакансий
 (
SELECT 
   AlertYear
 , AlertWeekName
 , AlertWeekNum
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
 , AlertWeekName
 , AlertWeekNum
 , NewVacancyCount
 , COUNT(SubscribeCompetitorID) AS AlertsCount
FROM SubscriptionsByNewJobs
GROUP BY 
   AlertYear
 , AlertWeekName
 , AlertWeekNum
 , NewVacancyCount;