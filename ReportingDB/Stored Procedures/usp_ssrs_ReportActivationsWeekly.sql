CREATE PROCEDURE [dbo].[usp_ssrs_ReportActivationsWeekly]
 @StartDate DATETIME, @EndDate DATETIME

AS

WITH NC_Flags AS
 (
SELECT 
   NC.NotebookId
 , dbo.fnGetDatePart(NC.AddDate) AS 'RegDate'
 , N.NotebookStateId
 , NC.IsCorporativeEMail
 , NC.IsLegalPerson
 , (SELECT COUNT(*) 
    FROM Analytics.dbo.Vacancy V
	WHERE V.NotebookId = NC.NotebookId
     AND EXISTS (SELECT * FROM Analytics.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 1)
     AND EXISTS (SELECT * FROM Analytics.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 2)
	 AND EXISTS (SELECT * FROM Analytics.dbo.VacancyPublishHistory WHERE VacancyId = V.Id)
     AND V.AddDate <= D.LastMonthDate + 1) AS VacCount
 , (SELECT COUNT(*)
    FROM Analytics.dbo.DailyViewedResume DVR
    WHERE NC.NotebookId = DVR.EmployerNotebookID
     AND DVR.ViewDate <= D.LastMonthDate + 1) AS ViewCount
 , (SELECT COUNT(*)
    FROM Analytics.dbo.NotebookCompany_Spent NCS
    WHERE NC.NotebookId = NCS.NotebookId
     AND NCS.AddDate <= D.LastMonthDate + 1) AS SpentCount
FROM Analytics.dbo.NotebookCompany NC
 JOIN Analytics.dbo.Notebook N ON NC.NotebookId = N.Id
 JOIN dbo.DimDate D ON dbo.fnGetDatePart(NC.AddDate) = D.FullDate
WHERE NOT EXISTS (SELECT * FROM Analytics.dbo.NotebookCompanyMerged NCM WHERE NCM.SourceNotebookId = NC.NotebookId)
 AND N.NotebookStateId IN (5,7)
 AND NC.AddDate BETWEEN @StartDate AND @EndDate
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
 , NotebookId
FROM NC_Flags NCF
 )
, NC_Grouped AS
 (
SELECT 
   RegDate
 , JurGroup
 , ActivityGroup
 , COUNT(*) AS CompaniesNum
FROM NC_IdByGroups NCIdBG
GROUP BY 
   RegDate
 , JurGroup
 , ActivityGroup
 )

SELECT 
   JurGroup
 , ActivityGroup
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
GROUP BY  
   JurGroup
 , ActivityGroup
 , DD.YearNum 
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.MonthNameEng
 , DD.WeekNum
 , DD.WeekName
 , DD.FullDate;