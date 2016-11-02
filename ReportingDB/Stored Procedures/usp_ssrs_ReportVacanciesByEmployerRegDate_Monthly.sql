
CREATE PROCEDURE [dbo].[usp_ssrs_ReportVacanciesByEmployerRegDate_Monthly]
 @StartDate DATETIME, @EndDate DATETIME

AS

--DECLARE @StartDate DATETIME;
--DECLARE @EndDate DATETIME;
--
--SET @StartDate = '20121101';
--SET @EndDate = '20130301';

WITH Vac_Flags AS
 (
SELECT
   V.Id AS VacancyId
 , dbo.fnGetDatePart(V.AddDate) AS VacAddDate
 , NC.NotebookId
 , dbo.fnGetDatePart(NC.AddDate) AS NcAddDate
FROM SRV16.RabotaUA2.dbo.Vacancy V
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC
  ON V.NotebookId = NC.NotebookId
WHERE 
 EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 1)
 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 2)
 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.VacancyPublishHistory WHERE VacancyId = V.Id)
 AND V.AddDate BETWEEN @StartDate AND @EndDate
UNION
SELECT
   VD.VacancyID
 , dbo.fnGetDatePart(VD.AddDate)
 , NC.NotebookId
 , dbo.fnGetDatePart(NC.AddDate)
FROM SRV16.RabotaUA2.dbo.Vacancy_Deleted VD
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC
  ON VD.NotebookId = NC.NotebookId
WHERE VD.Was_IsModerated = 1 AND VD.Was_IsModeratedRubric = 1
 AND VD.AddDate BETWEEN @StartDate AND @EndDate
 )
, VacIdsByGroups AS 
 (
SELECT 
   CASE 
    WHEN DATEDIFF(MONTH,NcAddDate,VacAddDate) = 0
     THEN '1.Новые вакансии, опубликованные блокнотами, зарег в отчетном календарном месяце'
    WHEN DATEDIFF(MONTH,NcAddDate,VacAddDate) <= 2
     THEN '2.Новые вакансии, опубликованные блокнотами, зарег в 2 предыдущих календарных месяца'
    ELSE '3.Новые вакансии, опубликованные остальными блокнотами'
   END AS 'VacNcRegGroup'
 , VacAddDate
 , VacancyId
FROM Vac_Flags
 )
, VacGrouped AS
 (
SELECT 
   VacNcRegGroup
 , VacAddDate
 , COUNT(*) AS VacCount
FROM VacIdsByGroups
GROUP BY
   VacNcRegGroup
 , VacAddDate
 )
SELECT 
   VacNcRegGroup
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
   VacNcRegGroup
 , DD.YearNum 
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.MonthNameEng
 , DD.WeekNum
 , DD.WeekName
 , DD.FullDate;