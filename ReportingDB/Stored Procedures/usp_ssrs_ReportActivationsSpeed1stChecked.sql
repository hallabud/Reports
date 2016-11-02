
CREATE PROCEDURE [dbo].[usp_ssrs_ReportActivationsSpeed1stChecked]

AS 

WITH CTE_Vacancies AS
 (
SELECT Id AS 'VacancyId', NotebookId, AddDate
FROM SRV16.RabotaUA2.dbo.Vacancy
UNION
SELECT VacancyID, NotebookID, AddDate
FROM SRV16.RabotaUA2.dbo.Vacancy_Deleted
 )
, NC_Flags AS
 (
SELECT
   NC.NotebookId
 , (SELECT COUNT(*) FROM CTE_Vacancies WHERE NotebookId = NC.NotebookId) AS 'TotalVacs'
 , ISNULL(CE.[Count],'не указано') AS 'CountEmpGroup'
 , ISNULL(CE.OrderNumber,0) AS 'OrderNum'
 , NC.AddDate AS 'RegDate'
 , (SELECT MIN(DateOfUpdate) FROM SRV16.RabotaUA2.dbo.Notebook_History 
     WHERE [Key] = NC.NotebookId AND Field = 'NotebookStateId' AND NewValue = 5) AS 'FirstChekedStatus'
FROM SRV16.RabotaUA2.dbo.NotebookCompany NC
 LEFT JOIN SRV16.RabotaUA2.dbo.NotebookCompanyCountEmployee_dir CE
  ON NC.CountEmp = CE.Id
 JOIN SRV16.RabotaUA2.dbo.Notebook N
  ON NC.NotebookId = N.Id
WHERE NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompanyMerged WHERE SourceNotebookId = NC.NotebookId)
 AND N.NotebookStateId IN (5,7)
 AND NC.AddDate >= DATEADD(MONTH, -3, GETDATE())
 )
, NC_GroupedIds AS
 (
SELECT
   NotebookId
 , CASE 
    WHEN TotalVacs >= 100 THEN '7.100+'
    WHEN TotalVacs >= 75 THEN '6.75-99'
    WHEN TotalVacs >= 50 THEN '5.50-74'
    WHEN TotalVacs >= 25 THEN '4.25-49'
    WHEN TotalVacs >= 10 THEN '3.10-24'
    WHEN TotalVacs >= 5 THEN '2.5-9'
    WHEN TotalVacs >= 1 THEN '1.1-4'
    ELSE '0.0'
   END AS 'TotalVacsGroup'
 , CountEmpGroup
 , OrderNum
 , CASE 
    WHEN DATEDIFF(DAY,RegDate,FirstChekedStatus) >= 15 THEN '15+'
    ELSE CAST(DATEDIFF(DAY,RegDate,FirstChekedStatus) AS VARCHAR)
   END AS 'DaysBeforeChecked'
FROM NC_Flags
WHERE FirstChekedStatus IS NOT NULL AND DATEDIFF(DAY,RegDate,FirstChekedStatus) >= 0
 )
SELECT 
   TotalVacsGroup
 , CountEmpGroup
 , OrderNum 
 , DaysBeforeChecked
 , COUNT(NotebookId) AS NotebookNum
FROM NC_GroupedIds
GROUP BY
   TotalVacsGroup
 , CountEmpGroup
 , OrderNum 
 , DaysBeforeChecked;

