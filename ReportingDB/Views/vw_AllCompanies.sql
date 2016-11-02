


CREATE VIEW [dbo].[vw_AllCompanies]

AS

SELECT DC.* 
 , (SELECT MAX(CompleteDate) FROM Analytics.dbo.CRM_Action A WHERE A.NotebookID = DC.NotebookId AND CompleteDate <= GETDATE() AND A.StateID = 2) AS LastActionDate
 , (SELECT MIN(ExecutionDate) FROM Analytics.dbo.CRM_Action A WHERE A.NotebookID = DC.NotebookId AND ExecutionDate > GETDATE() AND A.StateID = 1) AS NextActionDate
 , CASE 
	WHEN FCS.HasPaidPublishedVacs = 1 OR HasPaidPublicationsLeft = 1 OR HasHotPublishedVacs = 1 OR HasHotPublicationsLeft = 1 OR HasCVDBAccess = 1 OR HasActivatedLogo = 1 OR HasActivatedProfile = 1 THEN 1
	ELSE 0
   END AS HasPaidServices
 , (SELECT SUM(OAP.PaySum)
	FROM Analytics.dbo.Order_AccPayment OAP
	 JOIN Analytics.dbo.Order_Acc OA ON OAP.AccID = OA.ID AND OAP.AccYear = OA.Year
	 JOIN Analytics.dbo.Orders O ON OA.OrderID = O.ID
	WHERE PayDate >= '2015-01-01'
	 AND DC.NotebookId = O.NotebookID) AS PaymentSum_2015
 , CASE 
    WHEN EXISTS (SELECT *
					FROM Analytics.dbo.Order_AccPayment OAP
					 JOIN Analytics.dbo.Order_Acc OA ON OAP.AccID = OA.ID AND OAP.AccYear = OA.Year
					 JOIN Analytics.dbo.Orders O ON OA.OrderID = O.ID
					WHERE PayDate >= '2015-01-01'
					 AND DC.NotebookId = O.NotebookID) THEN 1 ELSE 0 END AS HasPayments_2015
FROM dbo.DimCompany DC
 JOIN dbo.FactCompanyStatuses FCS ON DC.Company_key = FCS.Company_key AND FCS.Date_key = (SELECT MAX(Date_key) FROM dbo.FactCompanyStatuses)

