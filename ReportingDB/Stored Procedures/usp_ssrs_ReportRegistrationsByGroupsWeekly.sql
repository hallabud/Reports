
CREATE PROCEDURE [dbo].[usp_ssrs_ReportRegistrationsByGroupsWeekly]
 @StartDate DATETIME, @EndDate DATETIME

AS

WITH NC_Flags AS 
 (
SELECT
   N.Id
 , N.AddDate
 , ISNULL(NC.IsConfirmed,0) AS 'IsEmailConfirmed'
 , CASE WHEN COALESCE(NC.BlockingReasonIDs,NC.BlockingReasonIDs2) IS NOT NULL THEN 1 ELSE 0 END AS 'IsBlocked'
 , (SELECT CASE WHEN MAX(ID) IS NULL THEN 0 ELSE 1 END
    FROM Analytics.dbo.NotebookCompanyMerged NCM 
    WHERE NCM.SourceNotebookID = N.Id) AS 'IsMergedInto' 
 , CASE WHEN N.NotebookStateId = 4 THEN 1 ELSE 0 END AS 'IsBlackList'
 , CASE WHEN N.NotebookStateId IN (5,7) THEN 1 ELSE 0 END AS 'IsMegaOrChecked'
 , CASE 
    WHEN NC.IsLegalPerson = 0 AND N.NotebookStateId = 7 THEN 'МП СПД'
    WHEN NC.IsLegalPerson = 0 AND N.NotebookStateId = 5 THEN 'неМП СПД'
    WHEN NC.IsLegalPerson = 1 AND N.NotebookStateId = 7 AND  NC.IsCorporativeEMail = 1 THEN 'МП ЮЛ - corp domain'
    WHEN NC.IsLegalPerson = 1 AND N.NotebookStateId = 7 AND  NC.IsCorporativeEMail = 0 THEN 'МП ЮЛ - free domain'
    WHEN NC.IsLegalPerson = 1 AND N.NotebookStateId = 5 THEN 'неМП ЮЛ'
    ELSE 'Другое' END AS 'SubGroup'
 , (SELECT COUNT(*) 
    FROM Analytics.dbo.Vacancy V
	WHERE 
     EXISTS (SELECT * FROM Analytics.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 1)
     AND EXISTS (SELECT * FROM Analytics.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 2)
	 AND EXISTS (SELECT * FROM Analytics.dbo.VacancyPublishHistory WHERE VacancyId = V.Id)
     AND DATEPART(MONTH,V.AddDate) = DATEPART(MONTH,N.AddDate) 
     AND DATEPART(YEAR,V.AddDate) = DATEPART(YEAR,N.AddDate)
     AND V.NotebookId = N.Id) AS VacCount
FROM Analytics.dbo.Notebook N
 JOIN Analytics.dbo.NotebookCompany NC ON N.Id = NC.NotebookId
 )
, RegsByGroupAndDate AS
 (
--SELECT 
--   'Всего' AS 'RegGroup'
-- , dbo.fnGetDatePart(AddDate) AS 'RegDate'
-- , SubGroup
-- , COUNT(*) AS 'RegCount' 
--FROM NC_Flags
--GROUP BY dbo.fnGetDatePart(AddDate), SubGroup
-- UNION ALL
SELECT 
   '1.Подтвердили email' AS 'RegGroup'
 , dbo.fnGetDatePart(AddDate) AS 'RegDate'
 , SubGroup
 , COUNT(*) AS 'RegCount' 
 , SUM(VacCount) AS 'SumVacCount'
FROM NC_Flags
WHERE IsEmailConfirmed = 1
GROUP BY dbo.fnGetDatePart(AddDate), SubGroup
 UNION ALL
SELECT 
   '3.Заблокированы' AS 'RegGroup'
 , dbo.fnGetDatePart(AddDate) AS 'RegDate'
 , SubGroup
 , COUNT(*) AS 'RegCount' 
 , SUM(VacCount)
FROM NC_Flags 
WHERE IsEmailConfirmed = 1 AND IsBlocked = 1
GROUP BY dbo.fnGetDatePart(AddDate), SubGroup
 UNION ALL
SELECT 
   '4.Слились в текущие блокноты'
 , dbo.fnGetDatePart(AddDate)
 , SubGroup
 , COUNT(*)
 , SUM(VacCount)
FROM NC_Flags 
WHERE IsEmailConfirmed = 1 AND IsBlocked = 0 AND IsMergedInto = 1
GROUP BY dbo.fnGetDatePart(AddDate), SubGroup
 UNION ALL 
SELECT 
   '5.Черный список'
 , dbo.fnGetDatePart(AddDate)
 , SubGroup
 , COUNT(*)
 , SUM(VacCount)
FROM NC_Flags
WHERE IsEmailConfirmed = 1 AND IsBlocked = 0 AND IsMergedInto = 0 AND IsBlackList = 1
GROUP BY dbo.fnGetDatePart(AddDate), SubGroup
 UNION ALL
SELECT 
   '2.Прошли проверку (П или МП)'
 , dbo.fnGetDatePart(AddDate)
 , SubGroup
 , COUNT(*)
 , SUM(VacCount)
FROM NC_Flags 
WHERE IsEmailConfirmed = 1 AND IsBlocked = 0 AND IsMergedInto = 0 AND IsBlackList = 0 AND IsMegaOrChecked = 1
GROUP BY dbo.fnGetDatePart(AddDate), SubGroup
 UNION ALL
SELECT 
   '6.Другие'
 , dbo.fnGetDatePart(AddDate)
 , SubGroup
 , COUNT(*)
 , SUM(VacCount)
FROM NC_Flags 
WHERE IsEmailConfirmed = 1 AND IsBlocked = 0 AND IsMergedInto = 0 AND IsBlackList = 0 AND IsMegaOrChecked = 0
GROUP BY dbo.fnGetDatePart(AddDate), SubGroup
 )

SELECT 
   RGD.RegGroup
 , SubGroup
 , DD.YearNum 
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.MonthNameEng
 , DD.WeekNum
 , DD.WeekName
 , DD.FullDate
 , SUM(RGD.RegCount) AS Registrations
 , SUM(RGD.SumVacCount) AS Vacancies
FROM RegsByGroupAndDate RGD
 JOIN Reporting.dbo.DimDate DD
  ON RGD.RegDate = DD.FullDate
WHERE DD.FullDate BETWEEN @StartDate AND @EndDate 
GROUP BY 
   RGD.RegGroup
 , SubGroup
 , DD.YearNum 
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.MonthNameEng
 , DD.WeekNum
 , DD.WeekName
 , DD.FullDate;