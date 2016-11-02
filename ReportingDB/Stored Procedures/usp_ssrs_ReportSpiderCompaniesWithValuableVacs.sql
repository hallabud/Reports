
CREATE PROCEDURE [dbo].[usp_ssrs_ReportSpiderCompaniesWithValuableVacs]

AS

DECLARE @ValuablePZIDs VARCHAR(MAX);

SELECT @ValuablePZIDs = ',' + REPLACE(STUFF (
(SELECT DISTINCT ',' + dbo.fnGetPZNamesBySynonymousID(SR.SynonymousId)
FROM SRV16.RabotaUA2.dbo.SynonymousRubricNEW SR
WHERE EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.RubricPriority RP WHERE RP.RubricID2 = SR.RubricId2 AND ProfLevel1 <> 0)
 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.Synonymous S WHERE SR.SynonymousId = S.SynonymousId)
FOR XML PATH ('')),1,2,''),', ',',') + ',';

--SELECT @ValuablePZIDs;

WITH ValuableVacancies AS 
 (
SELECT 
   SC.CompanyId AS 'CompanyWorkID'
 , SC.Name AS 'CompanyName'
 , SC.Site AS 'CompanySite'
 , SV.SpiderVacancyID
 , SV.Name
 , CASE WHEN SV.PZIDs_Name LIKE '%,%' THEN LEFT(SV.PZIDs_Name,CHARINDEX(',',SV.PZIDs_Name)-1) ELSE SV.PZIDs_Name END AS  'PZ_Name'
FROM SRV16.RabotaUA2.dbo.SpiderCompany SC
 JOIN SRV16.RabotaUA2.dbo.SpiderVacancy SV
  ON SC.CompanyId = SV.SpiderCompanyId AND SC.Source = SV.Source
WHERE SC.NotebookId IS NULL
 AND SC.Source = 1 AND SC.IsApproved = 1
 AND SV.IsPublish = 1 AND ISNULL(SV.PZIDs_Name,'') <> ''
 )
, ValueableCompanies AS
 (
SELECT DISTINCT CompanyWorkID, CompanyName, CompanySite
FROM ValuableVacancies 
WHERE CHARINDEX(',' + PZ_Name + ',', @ValuablePZIDs) > 0
 )
SELECT 
   CompanyWorkID
 , CompanyName
 , CompanySite
 , (SELECT COUNT(*) FROM SRV16.RabotaUA2.dbo.SpiderVacancy SV WHERE SV.SpiderCompanyID = VC.CompanyWorkID AND SV.Source = 1 AND SV.IsPublish = 1) AS VacPublished
 , (SELECT COUNT(*) FROM SRV16.RabotaUA2.dbo.SpiderVacancy SV WHERE SV.SpiderCompanyID = VC.CompanyWorkID AND SV.Source = 1 AND SV.IsPublish = 1 AND ISNULL(SV.CityID,0) <> 1) AS NotKievVacPublished
 FROM ValueableCompanies VC
ORDER BY VacPublished DESC

