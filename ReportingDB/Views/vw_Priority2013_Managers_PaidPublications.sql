
-- managers (paid by vacancies)
CREATE VIEW [dbo].[vw_Priority2013_Managers_PaidPublications]
AS
SELECT
   D.FullDate
 , CONVERT(VARCHAR,D.FullDate,104) AS FullDate104
 , M.Name AS Manager
 , COUNT(*) AS CompaniesNum
FROM dbo.FactCompanyStatuses CS
 JOIN dbo.DimDate D ON CS.Date_key = D.Date_key
 JOIN dbo.DimCompany C ON CS.Company_key = C.Company_key
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC ON C.NotebookID = NC.NotebookId
 JOIN SRV16.RabotaUA2.dbo.City CY ON NC.HeadquarterCityID = CY.ID
 JOIN SRV16.RabotaUA2.dbo.Manager M ON NC.ManagerId = M.Id
 JOIN SRV16.RabotaUA2.dbo.NotebookCompanyExtra NCE ON NC.NotebookID = NCE.NotebookID
WHERE NCE.Admin3_TrophyBrand_IsPriority2013 = 1
 AND D.WeekDayNum = 5
 AND (CS.HasPaidPublishedVacs = 1 OR CS.HasPaidPublicationsLeft = 1 OR CS.HasHotPublishedVacs = 1 OR CS.HasHotPublicationsLeft = 1)
GROUP BY
   D.FullDate
 , CONVERT(VARCHAR,D.FullDate,104)
 , M.Name;

