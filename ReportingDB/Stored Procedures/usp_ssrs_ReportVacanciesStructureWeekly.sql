
CREATE PROCEDURE [dbo].[usp_ssrs_ReportVacanciesStructureWeekly]
 @StartDate DATETIME, @EndDate DATETIME

AS

------------------------------------------------------------------------------
-- 1. Определить признак платности/бесплатности для первой публикации вакансии
------------------------------------------------------------------------------
WITH Vac_PubTypes AS
 (
SELECT 
   NCS.VacancyId
 , CASE 
    WHEN COALESCE(TP.TicketPaymentTypeID,RTP.TicketPaymentTypeID,NULL) < 5
     THEN 0 
    ELSE 1
   END AS 'IsFree'
FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent NCS
 JOIN (SELECT VacancyId, MIN(ID) AS MinId
	   FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent
	   GROUP BY VacancyId) AS MinSpentIDs
  ON NCS.ID = MinSpentIDs.MinId
 LEFT JOIN SRV16.RabotaUA2.dbo.TicketPayment TP
  ON NCS.SpendType <> 4 AND NCS.TicketPaymentID = TP.Id
 LEFT JOIN SRV16.RabotaUA2.dbo.RegionalTicketPayment RTP
  ON NCS.SpendType = 4 AND NCS.TicketPaymentID = RTP.Id
 )

------------------------------------------------------------------------------
-- 2.Проставить "флаги" вакансиям из выбранного временного интервала
------------------------------------------------------------------------------
, Vac_Flags AS
 (
SELECT 
   V.Id AS 'VacancyId'
 , Reporting.dbo.fnGetDatePart(V.AddDate) AS 'VacAddDate'
 , dbo.fnIsValuableVacancy(V.Id) AS 'IsValueableVacancy'
 , VE.AttractionLevel
 , NC.Rating
 , NC.HeadquarterCityId
 , VPT.IsFree
 , ISNULL(CAST(CNT.OrderNumber AS VARCHAR) + CNT.[Count],'0не указано') AS 'CountEmplGroup'
FROM SRV16.RabotaUA2.dbo.Vacancy V
 LEFT JOIN Vac_PubTypes VPT ON V.Id = VPT.VacancyId
 JOIN SRV16.RabotaUA2.dbo.VacancyExtra VE ON V.Id = VE.VacancyId
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC ON V.NotebookId = NC.NotebookId
 LEFT JOIN SRV16.RabotaUA2.dbo.NotebookCompanyCountEmployee_dir CNT ON NC.CountEmp = CNT.Id
WHERE 
 EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 1)
 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 2)
 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.VacancyPublishHistory WHERE VacancyId = V.Id)
 AND V.AddDate BETWEEN @StartDate AND @EndDate
 )

------------------------------------------------------------------------------
-- 3.Для каждого айди вакансии проставить соответствующую группу
------------------------------------------------------------------------------
, VacIdsByGroups AS
 (
SELECT
   CASE
    WHEN IsValueableVacancy = 1 AND AttractionLevel IN (4,5)
     THEN '1.Ценные с описанием на 4-5'
    WHEN IsValueableVacancy = 1 AND AttractionLevel = 3
     THEN '2.Ценные с описанием на 3'
    WHEN IsValueableVacancy = 0 AND AttractionLevel IN (4,5)
     THEN '3.Неценные с описанием на 4-5'
	WHEN IsValueableVacancy = 0 AND AttractionLevel = 3
     THEN '4.Неценные с описанием на 3'
	ELSE '5.Другие' 
   END AS 'VacValueGroup'
 , CASE
    WHEN Rating = 5 THEN '1.5'
    WHEN Rating = 4 THEN '2.4'
    WHEN Rating = 3 THEN '3.3'
    ELSE '4.Другие' 
   END AS 'NcRatingGroup'
 , CASE
    WHEN HeadquarterCityId = 1 THEN '1.Киев'
    WHEN HeadquarterCityId IN (2,3,4,6,21) THEN '2.Донецк, Днепр, Харьков, Одесса, Львов'
    ELSE '3.Другие' 
   END AS 'NcCityGroup'
 , CASE
    WHEN IsFree = 0 THEN '1.Платные публикации'
    WHEN IsFree = 1 THEN '2.Бесплатные публикации'
    ELSE '3.Неизвестно'
   END AS 'VacPubTypeGroup'
 , CountEmplGroup
 , VacAddDate
 , VacancyId
FROM Vac_Flags
 )

------------------------------------------------------------------------------
-- 4.Сгруппировать и посчитать кол-во вакансий в группах
------------------------------------------------------------------------------
, VacGrouped AS
 (
SELECT
   VacValueGroup
 , NcRatingGroup
 , NcCityGroup
 , VacPubTypeGroup
 , CountEmplGroup
 , VacAddDate
 , COUNT(*) AS VacCount
FROM VacIdsByGroups
GROUP BY 
   VacValueGroup
 , NcRatingGroup
 , NcCityGroup
 , VacPubTypeGroup
 , CountEmplGroup
 , VacAddDate
 )

------------------------------------------------------------------------------
-- 5.Итоговый датасет
------------------------------------------------------------------------------
SELECT 
   VacValueGroup
 , NcRatingGroup
 , NcCityGroup
 , VacPubTypeGroup
 , CountEmplGroup
 , DD.YearNum 
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.MonthNameEng
 , DD.WeekNum
 , DD.WeekName
 , DD.FullDate 
 , SUM(VacCount) AS SumVacCount
FROM VacGrouped VG
 JOIN Reporting.dbo.DimDate DD
  ON VG.VacAddDate = DD.FullDate
GROUP BY  
   VacValueGroup
 , NcRatingGroup
 , NcCityGroup
 , VacPubTypeGroup
 , CountEmplGroup
 , DD.YearNum 
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.MonthNameEng
 , DD.WeekNum
 , DD.WeekName
 , DD.FullDate;