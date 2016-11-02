
CREATE PROCEDURE [dbo].[usp_ssrs_ReportNewJobsMonthly_Emails_Without_Digest]

AS

SET DATEFIRST 1;

WITH NewJobsBySubscription AS 
-- группируем емейлы подписок по принципу 1 емейл - сумма новых вакансий в группах группирования
 (
SELECT 
   DATEPART(YEAR,Date) AS 'AlertYear'
 , DATEPART(MONTH,Date) AS 'AlertMonthNum'
 , DATENAME(MONTH,Date) AS 'AlertMonth'
 , SC.UserEMail 
 , SUM(ISNULL(NewVacancyCount,0)) AS SumNewVacancyCount
FROM Statistic.dbo.VacancySubscription_History VSH WITH (NOLOCK)
 JOIN SRV16.RabotaUA2.dbo.SubscribeCompetitor SC WITH (NOLOCK)
  ON VSH.SubscribeCompetitorID = SC.Id
WHERE NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor WITH (NOLOCK)
					WHERE SourceType IN (2,7) AND Id = VSH.SubscribeCompetitorId)
 AND DATEPART(WEEKDAY, Date) <> 1
GROUP BY DATEPART(YEAR,Date)
 , DATEPART(MONTH,Date)
 , DATENAME(MONTH,Date)
 , SC.UserEMail
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
 , UserEMail
FROM NewJobsBySubscription
 )
SELECT 
   AlertYear
 , AlertMonthNum
 , AlertMonth
 , NewVacancyCount
 , COUNT(UserEMail) AS EmailsCount
FROM SubscriptionsByNewJobs
GROUP BY 
   AlertYear
 , AlertMonthNum
 , AlertMonth
 , NewVacancyCount;