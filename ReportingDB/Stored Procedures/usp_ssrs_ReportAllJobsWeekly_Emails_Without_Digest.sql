
CREATE PROCEDURE [dbo].[usp_ssrs_ReportAllJobsWeekly_Emails_Without_Digest]

AS

SET DATEFIRST 1;

WITH NewJobsBySubscription AS 
-- группируем емейлы подписок по принципу 1 емейл - сумма новых вакансий в группах группирования
 (
SELECT 
   D.YearNum AS 'AlertYear'
 , D.WeekName AS 'AlertWeekName'
 , D.WeekNum AS 'AlertWeekNum'
 , SC.UserEMail 
 , SUM(ISNULL(TotalCount,0)) AS SumAllVacancyCount
FROM Statistic.dbo.VacancySubscription_History VSH
 JOIN SRV16.RabotaUA2.dbo.SubscribeCompetitor SC
  ON VSH.SubscribeCompetitorID = SC.Id
 JOIN Reporting.dbo.DimDate D
  ON VSH.Date = D.FullDate
WHERE NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor 
					WHERE SourceType IN (2,7) AND Id = VSH.SubscribeCompetitorId)
 AND D.WeekDayNum <> 1
GROUP BY D.YearNum
 , D.WeekName
 , D.WeekNum
 , SC.UserEMail
 )
, SubscriptionsByNewJobs AS
-- разбиваем на группы в зависимости от кол-во новых вакансий
 (
SELECT 
   AlertYear
 , AlertWeekName
 , AlertWeekNum
 , CASE 
    WHEN SumAllVacancyCount < 6 THEN CAST(SumAllVacancyCount AS VARCHAR)+' jobs'
    WHEN SumAllVacancyCount BETWEEN 6 AND 8 THEN '6 - 8 jobs'
    WHEN SumAllVacancyCount BETWEEN 9 AND 10 THEN '9 - 10 jobs'
    ELSE 'more than 10 jobs' END
   AS 'NewVacancyCount'
 , UserEMail
FROM NewJobsBySubscription
 )
SELECT 
   AlertYear
 , AlertWeekName
 , AlertWeekNum
 , NewVacancyCount
 , COUNT(UserEMail) AS EmailsCount
FROM SubscriptionsByNewJobs
GROUP BY 
   AlertYear
 , AlertWeekName
 , AlertWeekNum
 , NewVacancyCount;