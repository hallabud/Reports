
--EXEC dbo.usp_ssrs_ReportNewJobsZeroStructure;

CREATE PROCEDURE [dbo].[usp_ssrs_ReportNewJobsZeroStructure]

AS

SET DATEFIRST 1;

DECLARE @MaxDate DATETIME;

SELECT @MaxDate = MAX(Date) FROM Statistic.dbo.VacancySubscription_History;

WITH NewJobsBySubscription AS 
-- группируем подписки по принципу 1 подписка - сумма новых вакансий в группах группирования
 (
SELECT 
   SC.SourceType AS 'SourceType'
 , SC.CityID AS 'City'
 , ISNULL(R1.Name, 'Не определено') AS 'Rubric1'
 , ISNULL(SC.Keywords,'') AS 'Keywords'
 , ISNULL(SC.PZIDs_Name,'') AS 'PZIDs_Name'
 , SubscribeCompetitorID
 , SUM(ISNULL(NewVacancyCount,0)) AS SumNewVacancyCount
FROM Statistic.dbo.VacancySubscription_History VSH
 LEFT JOIN SRV16.RabotaUA2.dbo.SubscribeCompetitor SC
  ON VSH.SubscribeCompetitorID = SC.Id
 LEFT JOIN SRV16.RabotaUA2.dbo.Rubric1Level R1
  ON SC.RubricID1 = R1.Id
 WHERE NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor 
					WHERE SourceType IN (2,7) AND Id = VSH.SubscribeCompetitorId)
  AND Date = @MaxDate
GROUP BY 
   SC.SourceType
 , SC.CityID
 , ISNULL(SC.Keywords,'')
 , ISNULL(SC.PZIDs_Name,'')
 , ISNULL(R1.Name, 'Не определено')
 , SubscribeCompetitorID
HAVING SUM(ISNULL(NewVacancyCount,0)) = 0 
 )
, SubscriptionsByNewJobs AS
-- разбиваем на группы в зависимости от признаков группирования
 (
SELECT 
   CASE 
    WHEN NJBS.SourceType IN (1,4) THEN '1.IsFromApply + CreateFromVacancy'
    WHEN NJBS.SourceType = 3 THEN '2.CreateFromResume'
    WHEN NJBS.SourceType = 5 THEN '3.IsQuick'
    WHEN NJBS.SourceType = 6 THEN '4.NotebookID > 0'
    ELSE '5.Другое'
   END AS 'SourceTypeGroup'
 ,  CASE
     WHEN NJBS.City = 1 THEN '1.Киев'
     WHEN NJBS.City IN (2,3,4,6,21) THEN '2.Донецк, Днепр, Харьков, Одесса, Львов'
    ELSE '3.Другие' END AS 'City'
 , NJBS.Rubric1 
 , CASE 
    WHEN ISNULL(NJBS.Keywords,'') = '' AND ISNULL(NJBS.PZIDs_Name,'') = '' THEN '1.Нет ПЗ, нет ключевых слов'
    WHEN ISNULL(NJBS.Keywords,'') <> '' AND ISNULL(NJBS.PZIDs_Name,'') <> '' THEN '2.Есть ПЗ, есть ключевые слова'
    WHEN ISNULL(NJBS.Keywords,'') <> '' AND ISNULL(NJBS.PZIDs_Name,'') = '' THEN '3.Нет ПЗ, есть ключевые слова'
    WHEN ISNULL(NJBS.Keywords,'') = '' AND ISNULL(NJBS.PZIDs_Name,'') <> '' THEN '4.Есть ПЗ, нет ключевых слов'
    ELSE '5.Непонятное' 
   END AS 'PzAndKwGroup'
 , SubscribeCompetitorID
FROM NewJobsBySubscription NJBS
 )
SELECT 
   SourceTypeGroup
 , City
 , Rubric1
 , PzAndKwGroup
 , COUNT(SubscribeCompetitorID) AS AlertsCount
FROM SubscriptionsByNewJobs
GROUP BY 
   SourceTypeGroup
 , City
 , Rubric1
 , PzAndKwGroup;