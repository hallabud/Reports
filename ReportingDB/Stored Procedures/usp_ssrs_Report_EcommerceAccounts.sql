
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-02-03
-- Description:	Процедура возвращает список е-коммерс счетов и ряд полей с ними связанных,
--				созданных в диапазоне между @StartDate и @EndDate по указанному в параметре @Manager
--				перечню менеджеров
-- ======================================================================================================

CREATE PROCEDURE dbo.usp_ssrs_Report_EcommerceAccounts
	(@StartDate DATETIME, @EndDate DATETIME, @Manager NVARCHAR(1000))

AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

WITH C AS
 (
SELECT 
   OA.AddDate AS Acc_AddDate
 , OA.ID AS Acc_ID
 , NC.NotebookID
 , NC.Name AS NotebookName
 , (SELECT TOP (1) ManagerID FROM SRV16.RabotaUA2.dbo.Letter_Manager_Log WHERE NotebookID = NC.NotebookID AND AddDate >= OA.AddDate) AS Letter_ManagerID
 , (SELECT TOP (1) AddDate FROM SRV16.RabotaUA2.dbo.Letter_Manager_Log WHERE NotebookID = NC.NotebookID AND AddDate >= OA.AddDate) AS Letter_AddDate
 , ISNULL((SELECT TOP (1) 1 FROM SRV16.RabotaUA2.dbo.CRM_ManagerToNotebook_Chat_Detail WHERE StateID = 7 AND NotebookID = NC.NotebookID AND AddDate >= OA.AddDate),0) AS WantToWorkWith
 , COALESCE((SELECT TOP 1 NewValue FROM SRV16.RabotaUA2.dbo.NotebookCompany_History WHERE Field = 'ManagerID' AND NotebookID = NC.NotebookID AND DateOfUpd <= OA.AddDate ORDER BY DateOfUpd DESC), NC.ManagerID) AS ManagerID_AccTime
 , (SELECT TOP 1 AddDate FROM SRV16.RabotaUA2.dbo.CRM_Action WHERE NotebookID = NC.NotebookID AND AddDate >= OA.AddDate AND TypeID NOT IN (9) ORDER BY AddDate) AS Action_FirstAddDate
 , (SELECT TOP 1 CompleteDate FROM SRV16.RabotaUA2.dbo.CRM_Action WHERE NotebookID = NC.NotebookID AND AddDate >= OA.AddDate AND TypeID NOT IN (9) AND StateID = 2 ORDER BY CompleteDate) AS Action_FirstCompleteDate
FROM SRV16.RabotaUA2.dbo.Order_Acc OA
 JOIN SRV16.RabotaUA2.dbo.Orders O ON O.ID = OA.OrderID AND O.Type = 5 
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC ON O.NotebookID = NC.NotebookID
WHERE O.Type = 5
 AND OA.AddDate BETWEEN @StartDate AND @EndDate + 1
 )

SELECT 
   Acc_AddDate
 , Acc_ID
 , NotebookID
 , NotebookName
 , M.Name AS Letter_ManagerName
 , TL.Name AS Letter_TeamLeadName
 , Letter_AddDate
 , WantToWorkWith
 , Action_FirstAddDate
 , Action_FirstCompleteDate
 , CASE WHEN Action_FirstCompleteDate IS NOT NULL THEN 1 ELSE 0 END AS HasCompletedAction
 , DATEDIFF(MINUTE, Acc_AddDate, COALESCE(Action_FirstCompleteDate, GETDATE())) AS IdleMinutes
FROM C
 LEFT JOIN SRV16.RabotaUA2.dbo.Manager M ON C.Letter_ManagerID = M.Id
 LEFT JOIN SRV16.RabotaUA2.dbo.Manager TL ON M.TeamLead_ManagerID = TL.ID
WHERE ManagerID_AccTime IN (SELECT Id FROM SRV16.RabotaUA2.dbo.Manager WHERE Id IN (1,212) OR IsLoyaltyGroup = 1)
 AND Letter_ManagerID IN (SELECT Value FROM Reporting.dbo.udf_SplitString(@Manager,','))
ORDER BY Acc_AddDate DESC;
