
CREATE PROCEDURE dbo.[usp_ssrs_Report_NotApprovedVacanciesByMainUser]

AS


DECLARE @EndDate DATETIME = GETDATE();
DECLARE @StartDate DATETIME = DATEADD(WEEK, -1, GETDATE());

WITH C_Dates AS
 (
SELECT FullDate 
FROM Reporting.dbo.DimDate
WHERE FullDate BETWEEN @StartDate AND @EndDate
 )
SELECT C.FullDate, D.Name AS Department, M.Name AS Manager
 , (SELECT COUNT(DISTINCT VacancyID) 
	FROM Analytics.dbo.VacancyStateHistory VSH 
	 JOIN Analytics.dbo.Vacancy V ON VSH.VacancyId = V.Id
	 JOIN Analytics.dbo.NotebookCompany NC ON V.NotebookId = NC.NotebookId
	WHERE VSH.State = 8 
	 AND NC.ManagerId = M.Id
	 AND (DateTo IS NULL OR C.FullDate BETWEEN DateTime AND DateTimeUpd)) AS CntVacancy
FROM C_Dates C
 CROSS JOIN Analytics.dbo.Manager M
 JOIN Analytics.dbo.Departments D ON M.DepartmentID = D.ID
WHERE D.ID IN (2,3) AND M.IsForTesting = 0 AND IsReportExcluding = 0
ORDER BY Department, Manager, FullDate;

