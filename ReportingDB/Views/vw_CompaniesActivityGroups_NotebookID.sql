
CREATE VIEW [dbo].[vw_CompaniesActivityGroups_NotebookID]
 
AS

SELECT 
   DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.FullDate
 , CASE 
    WHEN PublicationsNumLast6Months >= 2 AND MonthsNumLast6Months >= 2 AND PublicationsNumLast3Months >= 1
     THEN 1
    ELSE 0
   END AS 'IsActive6'
 , CASE 
    WHEN PublicationsNumLast3Months >= 2 AND MonthsNumLast3Months >= 2
     THEN 1
    ELSE 0
   END AS 'IsActive3' 
 , CASE 
    WHEN PublicationsNumLast2Months >= 2 AND MonthsNumLast2Months >= 2
     THEN 1
    ELSE 0
   END AS 'IsActive2' 
 , DC.NotebookID
FROM dbo.FactCompanyStatuses CS
 JOIN dbo.DimDate DD ON CS.Date_key = DD.Date_key
 JOIN dbo.DimCompany DC ON CS.Company_key = DC.Company_key
WHERE PublicationsNumLast6Months IS NOT NULL AND PublicationsNumLast6Months > 0;