
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-06-10
-- Description:	Процедура возвращает список компаний имевших как минимум одну опубликованную вакансию
--				или на rabota.ua или на work.ua в течении последнего месяца, по которым не было 
--				осуществлено действие (в СРМ) любого типа, кроме "Задача", "Встреча", "Системное действие"
--				Выводятся такие поля:
--				- Айди блокнота
--				- Название компании
--				- Менеджер
--				- Индекс привлекательности
--				- Среднее кол-во вакансий за последние 3 мес.
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-07-01
-- Description:	Показывать компании, по которым действие было совершено менеджером отличным от 
--				закрепленным на данный момент за компанией
-- ======================================================================================================

CREATE PROCEDURE [dbo].[usp_ssrs_Report_CompanyCoverage_ActiveWithoutAction]
	(@StartDate DATETIME,
	 @EndDate DATETIME,
	 @ManagerIDs VARCHAR(1000))

AS

DECLARE @StartDateKey INT = (SELECT Date_key FROM Reporting.dbo.DimDate WHERE FullDate = @StartDate);
DECLARE @EndDateKey INT = (SELECT Date_key FROM Reporting.dbo.DimDate WHERE FullDate = @EndDate);

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
SELECT 
   NC.NotebookId
 , NC.Name AS CompanyName
 , M.Name AS Manager
 , NC.ManagerId
 , DC.IndexAttraction
 , DC.AvgLast3Month
FROM SRV16.RabotaUA2.dbo.NotebookCompany NC
 JOIN Reporting.dbo.DimCompany DC ON NC.NotebookId = DC.NotebookId
 JOIN SRV16.RabotaUA2.dbo.Manager M ON NC.ManagerID = M.ID
 JOIN SRV16.RabotaUA2.dbo.aspnet_Membership MMB ON M.aspnet_UserUIN = MMB.UserID
WHERE NC.ManagerId IN (SELECT Value FROM dbo.udf_SplitString (@ManagerIDs,','))
 AND EXISTS (SELECT * 
 			 FROM Reporting.dbo.FactCompanyStatuses FCS
			 WHERE DC.Company_key = FCS.Company_key
			  AND FCS.Date_key BETWEEN @StartDateKey AND @EndDateKey
			  AND FCS.VacancyNum | ISNULL(FCS.WorkVacancyNum,0) > 0)
 AND NOT EXISTS (SELECT * 
				 FROM SRV16.RabotaUA2.dbo.CRM_Action A 
				 WHERE A.NotebookID = NC.NotebookId 
				  AND A.StateID = 2
				  AND A.TypeID NOT IN (6,8,9)
				  AND A.CompleteDate BETWEEN @StartDate AND @EndDate + 1
				  AND MMB.Email = A.Responsible
 )
 
 AND NOT EXISTS (SELECT * FROM Analytics.dbo.NotebookCompanyMerged NCM WHERE NCM.SourceNotebookID = NC.NotebookID) -- BI-21
 AND ISNULL(NC.IsNetworkCompany,0) = 0 -- BI-21
 
ORDER BY IndexAttraction DESC, AvgLast3Month DESC;
