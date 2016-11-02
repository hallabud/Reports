
CREATE VIEW vw_NotebookCompanies AS 
 (
SELECT
   NC.NotebookID
 , DATEDIFF(MONTH, NC.AddDate, GETDATE()) AS MonthNumFromRegDate
 , NS.Name AS NotebookState
 , EP.Name AS EmployerPost
 , CntEmp.Count AS CountEmployees
 , C.Name AS CityName
 , NC.IsCorporativeEMail
 , NC.IsLegalPerson
 , CASE WHEN ISNULL(NC.ContactURL, '') <> '' THEN 1 ELSE 0 END AS WebsiteExists
 , CASE WHEN M.DepartmentID = 2 THEN 'SF' ELSE 'SMB' END AS SalesChannel
 , (SELECT COUNT(DISTINCT DATEPART(MONTH, AddDate)) FROM Analytics.dbo.NotebookCompany_Spent WHERE NotebookID = NC.NotebookId AND AddDate BETWEEN DATEADD(MONTH, -3, GETDATE()) AND GETDATE()) AS MonthsNumWithPubs3Month
 , (SELECT COUNT(DISTINCT DATEPART(MONTH, ViewDate)) FROM Analytics.dbo.DailyViewedResume WHERE EmployerNotebookID = NC.NotebookId AND ViewDate BETWEEN DATEADD(MONTH, -3, GETDATE()) AND GETDATE() - 1) AS MonthsNumWithContactsOpened3Month
 , (SELECT COUNT(*) FROM Analytics.dbo.MultiUser WHERE NotebookID = NC.NotebookId) AS MultiUserNum
 , (SELECT COUNT(*) FROM Analytics.dbo.NotebookCompany_Spent WHERE NotebookID = NC.NotebookId AND AddDate BETWEEN DATEADD(MONTH, -3, GETDATE()) AND GETDATE()) AS Publications3Month
 , (SELECT COUNT(*) FROM Analytics.dbo.DailyViewedResume WHERE EmployerNotebookID = NC.NotebookId AND ViewDate BETWEEN DATEADD(MONTH, -3, GETDATE()) AND GETDATE() - 1) AS ContactsOpened3Month
 , (SELECT COUNT(*) FROM Analytics.dbo.NotebookCompany_Spent WHERE NotebookID = NC.NotebookId AND AddDate BETWEEN DATEADD(MONTH, -1, GETDATE()) AND GETDATE()) AS Publications1Month
 , (SELECT COUNT(*) FROM Analytics.dbo.DailyViewedResume WHERE EmployerNotebookID = NC.NotebookId AND ViewDate BETWEEN DATEADD(MONTH, -1, GETDATE()) AND GETDATE() - 1) AS ContactsOpened1Month
FROM Analytics.dbo.NotebookCompany NC
 JOIN Analytics.dbo.Notebook N ON NC.NotebookId = N.Id
 JOIN Analytics.dbo.NotebookState NS ON N.NotebookStateId = NS.Id
 JOIN Analytics.dbo.Manager M ON NC.ManagerId = M.Id
 LEFT JOIN Analytics.dbo.EmployerPost EP ON NC.EmployerPostID = EP.ID
 LEFT JOIN Analytics.dbo.NotebookCompanyCountEmployee_dir CntEmp ON NC.CountEmp = CntEmp.Id
 LEFT JOIN Analytics.dbo.City C ON NC.HeadquarterCityId = C.Id
WHERE NOT EXISTS (SELECT * FROM Analytics.dbo.NotebookCompanyMerged NCM WHERE NCM.SourceNotebookID = NC.NotebookId)
)