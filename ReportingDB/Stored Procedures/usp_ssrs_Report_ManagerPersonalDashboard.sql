
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-08-16
-- Description:	Процедура возвращает список компаний, у которых в течении выбранных дат менялась разница
--				в вакансиях между работой и ворком.
-- ======================================================================================================

CREATE PROCEDURE [dbo].[usp_ssrs_Report_ManagerPersonalDashboard]
	(@StartDate DATETIME, @EndDate DATETIME, @Manager VARCHAR(100))

AS

WITH C AS
 (
SELECT
   DD.FullDate
 , DC.NotebookId
 , DC.WorkCompanyID
 , DC.CompanyName
 , DC.AgeGroup
 , DC.ManagerName
 , CASE 
    WHEN DC.IndexAttraction BETWEEN 7 AND 10 THEN 5 
    WHEN DC.IndexAttraction BETWEEN 4.5 AND 7 THEN 4 
    WHEN DC.IndexAttraction BETWEEN 3 AND 4.5 THEN 3
    WHEN DC.IndexAttraction BETWEEN 1 AND 3 THEN 2
    WHEN DC.IndexAttraction > 0 THEN 1
    ELSE 0
   END AS Stars
 , DC.IndexAttraction
 , FCS.VacancyDiffGroup AS Today
 , FCS.VacancyNum AS Today_VacancyNum
 , ISNULL(FCS.WorkVacancyNum, 0) AS Today_WorkVacancyNum
 , (SELECT VacancyDiffGroup FROM dbo.FactCompanyStatuses WHERE Company_key = FCS.Company_key AND Date_key = FCS.Date_key - 1) AS Yesterday
 , (SELECT VacancyNum FROM dbo.FactCompanyStatuses WHERE Company_key = FCS.Company_key AND Date_key = FCS.Date_key - 1) AS Yesterday_VacancyNum 
 , ISNULL((SELECT WorkVacancyNum FROM dbo.FactCompanyStatuses WHERE Company_key = FCS.Company_key AND Date_key = FCS.Date_key - 1),0) AS Yesterday_WorkVacancyNum
 , (SELECT TOP 1 CompleteDate FROM Analytics.dbo.CRM_Action A WHERE A.NotebookID = DC.NotebookId AND StateID = 2 AND IsNotInterested = 0 ORDER BY CompleteDate DESC) AS LastCompletedDate
 , (SELECT TOP 1 ExecutionDate FROM Analytics.dbo.CRM_Action A WHERE A.NotebookID = DC.NotebookId AND StateID IN (1,4) ORDER BY ExecutionDate ASC) AS NextActionDate
 , FCS.HasPaidServices  AS Rabota_Paid
 , FCS.HasHotPublishedVacs | FCS.HasHotPublicationsLeft AS Rabota_Hot
 , ISNULL((SELECT DISTINCT 1 FROM dbo.FactSpiderCompanyIndexes FSCI JOIN dbo.DimSpiderCompany DSC ON FSCI.SpiderCompanyID = DSC.SpiderCompanyID WHERE FSCI.Date_key = DD.Date_key AND DSC.NotebookId = DC.NotebookId AND (VacancyCount > 2 OR HotVacancyCount = 1 OR IsHasLogo = 1 OR IsBusiness = 1)),0) AS Work_Paid
 , ISNULL((SELECT DISTINCT 1 FROM dbo.FactSpiderCompanyIndexes FSCI JOIN dbo.DimSpiderCompany DSC ON FSCI.SpiderCompanyID = DSC.SpiderCompanyID WHERE FSCI.Date_key = DD.Date_key AND DSC.NotebookId = DC.NotebookId AND HotVacancyCount = 1),0) AS Work_Hot
FROM dbo.FactCompanyStatuses FCS
 JOIN dbo.DimDate DD ON FCS.Date_key = DD.Date_key
 JOIN dbo.DimCompany DC ON FCS.Company_key = DC.Company_key
WHERE DD.FullDate >= '2014-08-01'
 AND AgeGroup IN ('Подростки','Взрослые')
 AND WorkConnectionGroup = 'Привязанные компании'
 AND DD.FullDate BETWEEN @StartDate + 1 AND @EndDate 
 AND DC.ManagerEmail = @Manager
 )
SELECT * 
  , (Today_VacancyNum - Today_WorkVacancyNum) - (Yesterday_VacancyNum - Yesterday_WorkVacancyNum) AS Change
FROM C
WHERE Today <> Yesterday
ORDER BY FullDate, Change, IndexAttraction DESC;