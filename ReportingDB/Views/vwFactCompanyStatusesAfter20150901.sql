

CREATE VIEW [dbo].[vwFactCompanyStatusesAfter20150901]  

AS 

SELECT
   DD.Date_key  
 , DD.FullDate
 , DD.DayNum
 , DD.WeekDayNum
 , DC.Company_key 
 , DC.ManagerName
 , DC.DepartmentName
 , DC.Region_key
 , DC.AgeGroup
 , DC.WorkConnectionGroup
 , FCS.VacancyNum
 , FCS.WorkVacancyNum
 , FCS.UnqWorkVacancyNum
 , FCS.VacancyDiffGroup
 , DC.StarRating
 , DC.IndexAttraction
 , DC.ManagerStartDate
FROM dbo.DimCompany DC
 JOIN dbo.FactCompanyStatuses FCS ON DC.Company_key = FCS.Company_key
 JOIN dbo.DimDate DD ON FCS.Date_key = DD.Date_key
WHERE FCS.VacancyDiffGroup <> 'R = W = 0'
 AND DD.Date_key >= 5723;

