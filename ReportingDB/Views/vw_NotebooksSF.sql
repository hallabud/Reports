

CREATE VIEW [dbo].[vw_NotebooksSF]

AS 

SELECT M.Name AS Manager, NC.NotebookID, NC.Name AS NotebookName
 ,  CASE 
		(ISNULL(
		(SELECT DISTINCT 1 
		FROM Analytics.dbo.NotebookCompany_Spent NCS
		WHERE NC.NotebookID = NCS.NotebookID AND NCS.AddDate >= DATEADD(MONTH, -3, GETDATE())),0) 
		+ ISNULL(
		(SELECT DISTINCT 1 
		FROM Analytics.dbo.SpiderCompany SC
			JOIN Analytics.dbo.SpiderCompanyWorkHistory SCWH ON SC.CompanyId = SCWH.CompanyID AND SC.Source = 1
		WHERE SC.NotebookID = NC.NotebookID
			AND SCWH.Date >= DATEADD(MONTH, -3, GETDATE())
			AND SCWH.VacancyCount > 0),0)) 
	 WHEN 2 THEN 1 
	 ELSE  
		(ISNULL(
		(SELECT DISTINCT 1 
		FROM Analytics.dbo.NotebookCompany_Spent NCS
		WHERE NC.NotebookID = NCS.NotebookID AND NCS.AddDate >= DATEADD(MONTH, -3, GETDATE())),0) 
		+ ISNULL(
		(SELECT DISTINCT 1 
		FROM Analytics.dbo.SpiderCompany SC
			JOIN Analytics.dbo.SpiderCompanyWorkHistory SCWH ON SC.CompanyId = SCWH.CompanyID AND SC.Source = 1
		WHERE SC.NotebookID = NC.NotebookID
			AND SCWH.Date >= DATEADD(MONTH, -3, GETDATE())
			AND SCWH.VacancyCount > 0),0)) 
	END 
	AS HasPubs3Mnth
 , ISNULL(
   (SELECT DISTINCT 1
    FROM Analytics.dbo.CRM_Action A
	WHERE A.NotebookID = NC.NotebookID
	 AND A.StateID = 2
	 AND A.CompleteDate >= DATEADD(MONTH, -3, GETDATE())),0) AS HasActions3Mnth
 , ISNULL(
   (SELECT DISTINCT 1
    FROM Reporting.dbo.FactCompanyStatuses FCS
	 JOIN Reporting.dbo.DimCompany DC ON FCS.Company_key = DC.Company_key
	 JOIN Reporting.dbo.DimDate DD ON FCS.Date_key = DD.Date_key
	WHERE DC.NotebookId = NC.NotebookID 
	 AND DD.FullDate  >= DATEADD(MONTH, -3, GETDATE())
	 AND (HasPaidPublishedVacs = 1 OR HasPaidPublicationsLeft = 1 OR HasHotPublishedVacs = 1 OR HasHotPublicationsLeft = 1 OR HasCVDBAccess = 1 OR HasActivatedLogo = 1 OR HasActivatedProfile = 1)),0) AS IsClient 
FROM Analytics.dbo.NotebookCompany NC WITH (NOLOCK) 
 JOIN Analytics.dbo.Notebook N WITH (NOLOCK) ON NC.NotebookID = N.ID
 JOIN Analytics.dbo.Manager M WITH (NOLOCK) ON NC.ManagerID = M.ID
WHERE NOT EXISTS (SELECT * FROM Analytics.dbo.NotebookCompanyMerged NCM WITH (NOLOCK) WHERE NCM.SourceNotebookID = NC.NotebookID)
 AND N.NotebookStateID IN (5,7)
 AND M.DepartmentID = 2
 AND M.IsReportExcluding = 0
 AND NC.IsNetworkCompany = 0
 AND ISNULL(NC.IsNonResident,0) = 0
 AND EXISTS (SELECT * FROM Analytics.dbo.aspnet_Membership M WHERE M.UserId = N.aspnet_UserUIN)

