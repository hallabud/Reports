
-- 114356
-- 114310

CREATE VIEW [dbo].[vw_ClientPortfolio]

AS

SELECT DC.NotebookID, DC.CompanyName, ManagerName, DC.AvgLast3Month, C.Name AS Region, B.Name AS Branch
 , CASE 
    WHEN FCS.HasPaidPublishedVacs = 1 OR FCS.HasPaidPublicationsLeft = 1 OR FCS.HasHotPublishedVacs = 1 OR FCS.HasHotPublicationsLeft = 1 OR FCS.HasCVDBAccess = 1 OR HasActivatedLogo = 1 OR HasActivatedProfile = 1 THEN 'Платная компания'
	ELSE 'Не платная'
   END AS RabotaPaid
 , ISNULL(
   (SELECT DISTINCT 'Платная компания'
    FROM dbo.DimSpiderCompany DSC
	 JOIN dbo.FactSpiderCompanyIndexes FSCI ON DSC.SpiderCompanyID = FSCI.SpiderCompanyID
    WHERE DSC.SpiderSource_key = 1 AND FSCI.Date_key = LMD.Date_key AND DSC.NotebookId = DC.NotebookId
	 AND (FSCI.HotVacancyCount > 1 OR FSCI.IsHasLogo > 1 OR FSCI.VacancyCount > 3 OR FSCI.IsPaidByTickets = 1 OR Paid = 1)), 'Не платная') AS WorkPaid
 , ISNULL(
   (SELECT DISTINCT 'Бизнес-размещение'
	FROM dbo.DimSpiderCompany DSC
	 JOIN dbo.FactSpiderCompanyIndexes FSCI ON DSC.SpiderCompanyID = FSCI.SpiderCompanyID
    WHERE DSC.SpiderSource_key = 1 AND FSCI.Date_key = TD.Date_key AND DSC.NotebookId = DC.NotebookId AND FSCI.IsBusiness = 1), 'Не бизнес') AS IsBusiness
 , CASE 
    WHEN DC.AvgLast3Month <= 1.59 THEN 'До 1,59'
	WHEN DC.AvgLast3Month BETWEEN 1.59 AND 3.59 THEN 'От 1,6 до 3,59'
	WHEN DC.AvgLast3Month BETWEEN 3.6 AND 5.59 THEN 'От 3,6 до 5,59'
	WHEN DC.AvgLast3Month >= 5.59 THEN 'От 5,6'
   END AS AvgVacancyGroup
 , DepartmentName
 , CASE 
    WHEN DR.AnalyticsDbId IN (12, 33, 34, 29) OR C.OblastCityID = 29 OR NC.IsNetworkCompany = 1 THEN 'Non Resident'
	ELSE 'UA Company'
   END AS CompanyRegion
 , CASE NC.SalesChannel_Recommended
    WHEN 2 THEN 'Sales Force'
	WHEN 1 THEN 'Telesales'
	ELSE 'Unknown'
   END AS RecommendedChannel
 , NS.Name AS NotebookState
FROM dbo.DimCompany DC
 JOIN dbo.DimRegion DR ON DC.Region_key = DR.Region_key
 JOIN Analytics.dbo.City C ON DR.AnalyticsDbId = C.Id
 JOIN Analytics.dbo.NotebookCompany NC ON DC.NotebookId = NC.NotebookID
 JOIN Analytics.dbo.Notebook N ON NC.NotebookId = N.Id
 JOIN Analytics.dbo.NotebookState NS ON N.NotebookStateId = NS.Id
 CROSS JOIN (SELECT Date_key, FullDate FROM dbo.DimDate WHERE FullDate = dbo.fnGetDatePart(GETDATE())) TD
 CROSS JOIN (SELECT Date_key, FullDate FROM dbo.DimDate WHERE FullDate = dbo.fnGetDatePart(DATEADD(DAY, - DAY(GETDATE()), GETDATE()))) LMD
 JOIN dbo.FactCompanyStatuses FCS ON DC.Company_key = FCS.Company_key AND FCS.Date_key = TD.Date_key
 JOIN Analytics.dbo.Branch B ON NC.BranchId = B.ID
