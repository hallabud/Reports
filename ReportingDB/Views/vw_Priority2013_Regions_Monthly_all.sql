

-- regions
CREATE VIEW [dbo].[vw_Priority2013_Regions_Monthly_all]
AS
SELECT 
   DATEADD(DAY,-1,D.FullDate) AS FullDate
 , CONVERT(VARCHAR,DATEADD(DAY,-1,D.FullDate),104) AS FullDate104
 , CASE CY.Name
	WHEN 'Киев' THEN '1.Киев'
    WHEN 'Донецк' THEN '2.Донецк'
    WHEN 'Днепропетровск' THEN '3.Днепропетровск'
    WHEN 'Харьков' THEN '4.Харьков'
    WHEN 'Львов' THEN '5.Львов'
    WHEN 'Одесса' THEN '6.Одесса'
    ELSE '9.Вся Украина за исключением Киева и крупных городов' 
   END AS City
 , COUNT(*) AS CompaniesNum
FROM dbo.FactCompanyStatuses CS
 JOIN dbo.DimDate D ON CS.Date_key = D.Date_key
 JOIN dbo.DimCompany C ON CS.Company_key = C.Company_key
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC ON C.NotebookID = NC.NotebookId
 JOIN SRV16.RabotaUA2.dbo.City CY ON NC.HeadquarterCityID = CY.ID
 JOIN SRV16.RabotaUA2.dbo.NotebookCompanyExtra NCE ON NC.NotebookID = NCE.NotebookID
WHERE /*NCE.Admin3_TrophyBrand_IsPriority2013 = 1
 AND*/ D.DayNum = 1
 AND (CS.HasPaidPublishedVacs = 1 OR CS.HasPaidPublicationsLeft = 1 OR CS.HasHotPublishedVacs = 1 OR CS.HasHotPublicationsLeft = 1 OR CS.HasCVDBAccess = 1 OR CS.HasActivatedLogo = 1 OR CS.HasActivatedProfile = 1)
GROUP BY 
   DATEADD(DAY,-1,D.FullDate)
 , CONVERT(VARCHAR,DATEADD(DAY,-1,D.FullDate),104)
 , CASE CY.Name
	WHEN 'Киев' THEN '1.Киев'
    WHEN 'Донецк' THEN '2.Донецк'
    WHEN 'Днепропетровск' THEN '3.Днепропетровск'
    WHEN 'Харьков' THEN '4.Харьков'
    WHEN 'Львов' THEN '5.Львов'
    WHEN 'Одесса' THEN '6.Одесса'
    ELSE '9.Вся Украина за исключением Киева и крупных городов' 
   END;


