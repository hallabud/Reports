
CREATE PROCEDURE [dbo].[usp_ssrs_ReportRegistrationsByGroupsVacsWeekly]
 @StartDate DATETIME, @EndDate DATETIME

AS

WITH NC_Flags AS 
 (
SELECT
   N.AddDate AS 'RegDate'
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
WHERE N.NotebookStateId IN (5,7)
 )
, VCnt AS
 (
SELECT 
   dbo.fnGetDatePart(RegDate) AS RegDate
 , SubGroup
 , SUM(VacCount) AS SumVacCount
FROM NC_Flags NCF
GROUP BY 
   dbo.fnGetDatePart(RegDate)
 , SubGroup
 )
SELECT 
   DD.YearNum 
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.MonthNameEng
 , DD.WeekNum
 , DD.WeekName
 , DD.FullDate
 , SubGroup
 , SumVacCount
FROM VCnt
 JOIN Reporting.dbo.DimDate DD ON VCnt.RegDate = DD.FullDate
WHERE DD.FullDate BETWEEN @StartDate AND @EndDate;