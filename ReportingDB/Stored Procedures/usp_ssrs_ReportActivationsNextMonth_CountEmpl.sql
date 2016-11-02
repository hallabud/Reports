
CREATE PROCEDURE [dbo].[usp_ssrs_ReportActivationsNextMonth_CountEmpl]
 @MonthNum INT, @YearNum INT

AS

--DECLARE @MonthNum INT;
--DECLARE @YearNum INT;
--
--SET @MonthNum = 1;
--SET @YearNum = 2013;

WITH NC_Flags AS
 (
SELECT 
   NC.NotebookId
 , dbo.fnGetDatePart(NC.AddDate) AS 'RegDate'
 , N.NotebookStateId
 , NC.IsCorporativeEMail
 , NC.IsLegalPerson
 , ISNULL(CNT.[Count],'Неизвестно') AS 'CountEmpl'
 , (SELECT COUNT(*) 
    FROM SRV16.RabotaUA2.dbo.Vacancy V
	WHERE 
     V.NotebookId = NC.NotebookId
     AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 1)
     AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 2)
	 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.VacancyPublishHistory WHERE VacancyId = V.Id)
     AND DATEPART(MONTH,V.AddDate) = DATEPART(MONTH,NC.AddDate) 
     AND DATEPART(YEAR,V.AddDate) = DATEPART(YEAR,NC.AddDate)) AS VacCount
 , (SELECT COUNT(*) 
    FROM SRV16.RabotaUA2.dbo.Vacancy V
	WHERE 
     V.NotebookId = NC.NotebookId
     AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 1)
     AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 2)
	 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.VacancyPublishHistory WHERE VacancyId = V.Id)
     AND DATEPART(MONTH,V.AddDate) = DATEPART(MONTH,DATEADD(MONTH,1,NC.AddDate))
     AND (CASE 
		  WHEN DATEPART(MONTH,NC.AddDate) = 12 
           THEN DATEPART(YEAR,DATEADD(YEAR,1,NC.AddDate))
          ELSE DATEPART(YEAR,NC.AddDate) END) = DATEPART(YEAR,V.AddDate)
       ) AS NextMonthVacCount
 , (SELECT COUNT(*) 
    FROM SRV16.RabotaUA2.dbo.Vacancy V
     JOIN SRV16.RabotaUA2.dbo.VacancyPublishHistory VPH 
      ON VPH.VacancyId = V.Id
	WHERE 
     V.NotebookId = NC.NotebookId
     AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 1)
     AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 2)
     AND DATEPART(MONTH,VPH.AddDate) = DATEPART(MONTH,DATEADD(MONTH,1,NC.AddDate))
     AND (CASE 
		  WHEN DATEPART(MONTH,NC.AddDate) = 12 
           THEN DATEPART(YEAR,DATEADD(YEAR,1,NC.AddDate))
          ELSE DATEPART(YEAR,NC.AddDate) END) = DATEPART(YEAR,VPH.AddDate)
       ) AS NextMonthRepublish
 , (SELECT COUNT(*)
    FROM SRV16.RabotaUA2.dbo.DailyViewedResume DVR
    WHERE NC.NotebookId = DVR.EmployerNotebookID
     AND DATEPART(MONTH,DVR.ViewDate) = DATEPART(MONTH,NC.AddDate) 
     AND DATEPART(YEAR,DVR.ViewDate) = DATEPART(YEAR,NC.AddDate)) AS ViewCount
 , (SELECT COUNT(*)
    FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent NCS
    WHERE NC.NotebookId = NCS.NotebookId
     AND DATEPART(MONTH,NCS.AddDate) = DATEPART(MONTH,NC.AddDate) 
     AND DATEPART(YEAR,NCS.AddDate) = DATEPART(YEAR,NC.AddDate)) AS SpentCount
FROM SRV16.RabotaUA2.dbo.NotebookCompany NC
 JOIN SRV16.RabotaUA2.dbo.Notebook N ON NC.NotebookId = N.Id
 LEFT JOIN SRV16.RabotaUA2.dbo.NotebookCompanyCountEmployee_dir CNT ON NC.CountEmp = CNT.Id
WHERE NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompanyMerged NCM WHERE NCM.SourceNotebookId = NC.NotebookId)
 AND N.NotebookStateId IN (5,7)
 )
, NC_IdByGroups AS
 (
SELECT 
   RegDate
 , CASE 
    WHEN IsLegalPerson = 1 AND IsCorporativeEmail = 0 THEN '1.ЮЛ, зарегистрированные на некорп email'
    WHEN IsLegalPerson = 1 AND IsCorporativeEmail = 1 AND NotebookStateId = 7 THEN '2.ЮЛ, зарегистрированные на корп email (МП)'
    WHEN IsLegalPerson = 0 THEN '3.ФЛ, которые прошли проверку (П или МП)'
    ELSE '4.Непонятные'
   END AS 'JurGroup'
 , CASE 
    WHEN VacCount > 1 AND NotebookStateId = 7 THEN '1.Опубликовали более 1-й вакансии  + МП'
    WHEN VacCount = 1 AND NotebookStateId = 7 THEN '2.Опубликовали 1-у вакансию + МП'
    -- WHEN VacCount > 1 AND NotebookStateId = 5 THEN '3.Опубликовали более 1-й вакансии + неМП'
    WHEN VacCount = 1 AND NotebookStateId = 5 THEN '4.Опубликовали 1-у вакансию + неМП'
    WHEN VacCount = 0 AND NotebookStateId = 7 AND SpentCount > 0 THEN '5.Потратили публикацию + МП'
    WHEN VacCount = 0 AND NotebookStateId = 5 AND SpentCount > 0 THEN '6.Потратили публикацию + неМП'
    WHEN VacCount = 0 AND NotebookStateId = 7 AND SpentCount = 0 AND ViewCount > 0 THEN '7.Не тратили публикаций + МП + открывали контакты'
    WHEN VacCount = 0 AND NotebookStateId = 5 AND SpentCount = 0 AND ViewCount > 0 THEN '8.Не тратили публикаций + неМП + открывали контакты'
    WHEN VacCount = 0 AND NotebookStateId = 5 AND SpentCount = 0 AND ViewCount = 0 THEN '9.Не тратили публикаций + неМП + не открывали контакты'
   ELSE 'Другое' END AS 'ActivityGroup'
 , CASE
    WHEN NextMonthVacCount > 1 THEN '1.Более 1-й нов. вакансии в след. месяце'
    WHEN NextMonthVacCount = 1 THEN '2.1-а нов. вакансия в след. месяце'
    WHEN NextMonthVacCount = 0 AND NextMonthRepublish > 0 THEN '3.Хотя бы 1 раз продлевали'
   ELSE '4.0 нов. вакансий в след. месяце' END AS 'NextMonthActivity'
 , CountEmpl
 , NotebookId
FROM NC_Flags NCF
 )
, NC_Grouped AS
 (
SELECT 
   RegDate
 , JurGroup
 , ActivityGroup
 , NextMonthActivity
 , CountEmpl
 , COUNT(*) AS CompaniesNum
FROM NC_IdByGroups NCIdBG
WHERE JurGroup <> '4.Непонятные'
GROUP BY 
   RegDate
 , JurGroup
 , ActivityGroup
 , NextMonthActivity
 , CountEmpl
 )

SELECT 
   JurGroup
 , ActivityGroup
 , NextMonthActivity
 , CountEmpl
 , DD.YearNum 
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.MonthNameEng
 , DD.WeekNum
 , DD.WeekName
 , DD.FullDate 
 , SUM(CompaniesNum) AS SumCompaniesNum
FROM NC_Grouped NCG
 JOIN Reporting.dbo.DimDate DD
  ON NCG.RegDate = DD.FullDate
WHERE DD.MonthNum = @MonthNum AND DD.YearNum = @YearNum
GROUP BY  
   JurGroup
 , ActivityGroup
 , NextMonthActivity 
 , CountEmpl
 , DD.YearNum 
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.MonthNameEng
 , DD.WeekNum
 , DD.WeekName
 , DD.FullDate;