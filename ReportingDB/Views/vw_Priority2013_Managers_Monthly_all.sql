
-- managers
CREATE VIEW [dbo].[vw_Priority2013_Managers_Monthly_all]
AS
SELECT
   DATEADD(DAY,-1,D.FullDate) AS FullDate
 , CONVERT(VARCHAR,DATEADD(DAY,-1,D.FullDate),104) AS FullDate104
 , M.Name AS Manager
 , COUNT(*) AS CompaniesNum
FROM dbo.FactCompanyStatuses CS
 JOIN dbo.DimDate D ON CS.Date_key = D.Date_key
 JOIN dbo.DimCompany C ON CS.Company_key = C.Company_key
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC ON C.NotebookID = NC.NotebookId
 JOIN SRV16.RabotaUA2.dbo.City CY ON NC.HeadquarterCityID = CY.ID
 JOIN SRV16.RabotaUA2.dbo.Manager M ON NC.ManagerId = M.Id
 JOIN SRV16.RabotaUA2.dbo.NotebookCompanyExtra NCE ON NC.NotebookID = NCE.NotebookID
WHERE /*NCE.Admin3_TrophyBrand_IsPriority2013 = 1
 AND*/ D.DayNum = 1
 AND (CS.HasPaidPublishedVacs = 1 OR CS.HasPaidPublicationsLeft = 1 OR CS.HasHotPublishedVacs = 1 OR CS.HasHotPublicationsLeft = 1 OR CS.HasCVDBAccess = 1 OR CS.HasActivatedLogo = 1 OR CS.HasActivatedProfile = 1)
GROUP BY
   DATEADD(DAY,-1,D.FullDate)
 , CONVERT(VARCHAR,DATEADD(DAY,-1,D.FullDate),104)
 , M.Name;


