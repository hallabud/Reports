
CREATE PROCEDURE [dbo].[usp_ssrs_ReportNewJobsDaily_Emails]
 (@StartDate DATETIME, @EndDate DATETIME)

AS 

SET DATEFIRST 1;

WITH NewJobsBySubscription AS 
-- группируем емейлы подписок по принципу 1 емейл - сумма новых вакансий в группах группирования
 (
SELECT 
   DATEPART(YEAR,Date) AS 'AlertYear'
 , DATEPART(WEEK,Date) AS 'AlertWeekNum'
 , DATENAME(WEEKDAY,Date) AS 'AlertWeekDay'
 , Date AS 'AlertDateDT'
 , CONVERT(VARCHAR, Date, 104) AS 'AlertDate'
 , SC.UserEMail 
 , SUM(ISNULL(NewVacancyCount,0)) AS SumNewVacancyCount
FROM Statistic.dbo.VacancySubscription_History VSH WITH (NOLOCK)
 JOIN SRV16.RabotaUA2.dbo.SubscribeCompetitor SC WITH (NOLOCK)
  ON VSH.SubscribeCompetitorID = SC.Id
WHERE 1=0 and NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor WITH (NOLOCK)
					WHERE SourceType IN (2,7) AND Id = VSH.SubscribeCompetitorId)
 AND Date BETWEEN @StartDate AND @EndDate
GROUP BY DATEPART(YEAR,Date)
 , DATEPART(WEEK,Date)
 , DATENAME(WEEKDAY,Date)
 , Date
 , CONVERT(VARCHAR, Date, 104)
 , SC.UserEMail
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
 , UserEMail
FROM NewJobsBySubscription
 )
SELECT 
   AlertYear
 , AlertWeekNum
 , AlertWeekDay
 , AlertDateDT
 , AlertDate
 , NewVacancyCount
 , COUNT(UserEMail) AS EmailsCount
FROM SubscriptionsByNewJobs
GROUP BY 
   AlertYear
 , AlertWeekNum
 , AlertWeekDay
 , AlertDateDT
 , AlertDate
 , NewVacancyCount;