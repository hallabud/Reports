CREATE VIEW [dbo].[vw_Companies_CurrentActivityState]
AS

SELECT
   C.NotebookId
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
FROM dbo.FactCompanyStatuses CS
 JOIN dbo.DimCompany C ON CS.Company_key = C.Company_key
WHERE Date_key = (SELECT MAX(Date_key) FROM dbo.FactCompanyStatuses)