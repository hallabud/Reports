
CREATE PROCEDURE [dbo].[usp_ssrs_ReportCompaniesForm]
AS

SELECT
   CS.Company_key
 , NC.Name AS 'CompanyName'
 , M.Name AS 'ManagerName'
 , DD.WeekNum
 , DD.WeekName
 , CASE 
    WHEN SUM(CAST(HasPaidPublishedVacs AS INT)) > 0 AND SUM(CAST(HasPaidPublicationsLeft AS INT)) > 0 THEN 'green'
    WHEN SUM(CAST(HasPaidPublicationsLeft AS INT)) > 0 THEN 'lime'
    WHEN SUM(CAST(HasPaidPublishedVacs AS INT)) > 0 THEN 'yellow'
    ELSE 'red'
   END AS 'CardColor'
FROM Reporting.dbo.DimCompany DC
 JOIN Analytics.dbo.NotebookCompany NC ON DC.NotebookId = NC.NotebookId
 JOIN Analytics.dbo.Manager M ON NC.ManagerId = M.Id
 JOIN dbo.FactCompanyStatuses CS ON DC.Company_key = CS.Company_key
 JOIN dbo.DimDate DD ON CS.Date_key = DD.Date_key
WHERE DD.FullDate > DATEADD(WEEK, -14, GETDATE())
 AND EXISTS (SELECT * 
			 FROM dbo.FactCompanyStatuses CS2
			  JOIN dbo.DimDate DD2 ON CS2.Date_key = DD2.Date_key
			 WHERE CS2.Company_key = CS.Company_key 
			  AND DD2.FullDate > DATEADD(WEEK, -14, GETDATE())
			  AND (HasPaidPublicationsLeft = 1 OR HasPaidPublishedVacs = 1))
GROUP BY  
   CS.Company_key 
 , NC.Name
 , M.Name
 , DD.WeekNum
 , DD.WeekName