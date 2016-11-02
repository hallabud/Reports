
CREATE PROCEDURE [dbo].[usp_ssrs_ReportEcommerceMonthly_Part1]
AS
SELECT 
   D.Fulldate
 , CONVERT(VARCHAR, D.Fulldate, 104) AS FullDate104
 , CASE 
    WHEN (HasPaidPublishedVacs = 1 OR HasPaidPublicationsLeft = 1) AND (HasHotPublishedVacs = 1 OR HasHotPublicationsLeft = 1 OR HasCVDBAccess = 1 OR HasActivatedLogo = 1 OR HasActivatedProfile = 1)  THEN '0.Из них есть и платные вакансии, и доп. сервис'
    WHEN HasPaidPublishedVacs = 1 OR HasPaidPublicationsLeft = 1 THEN '1.Из них есть платные вакансии'
    WHEN HasHotPublishedVacs = 1 OR HasHotPublicationsLeft = 1 OR HasCVDBAccess = 1 OR HasActivatedLogo = 1 OR HasActivatedProfile = 1 THEN '2.Из них есть доп.сервис'
    ELSE '9.Нет платного сервиса на счету'
   END AS PaidGroup
 , COUNT(DISTINCT CS.Company_key) AS CompaniesNum
FROM dbo.FactCompanyStatuses CS
 JOIN dbo.DimCompany C ON CS.Company_key = C.Company_key
 JOIN dbo.DimDate D ON CS.Date_key = D.Date_key
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC ON C.NotebookId = NC.NotebookId
WHERE NC.ManagerID IN (156,159) 
 AND D.DayNum = 1 
 AND NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompanyMerged NCM WHERE NCM.SourceNotebookId = NC.NotebookId)
GROUP BY 
   D.Fulldate
 , CONVERT(VARCHAR, D.Fulldate, 104)
 , CASE 
    WHEN (HasPaidPublishedVacs = 1 OR HasPaidPublicationsLeft = 1) AND (HasHotPublishedVacs = 1 OR HasHotPublicationsLeft = 1 OR HasCVDBAccess = 1 OR HasActivatedLogo = 1 OR HasActivatedProfile = 1)  THEN '0.Из них есть и платные вакансии, и доп. сервис'
    WHEN HasPaidPublishedVacs = 1 OR HasPaidPublicationsLeft = 1 THEN '1.Из них есть платные вакансии'
    WHEN HasHotPublishedVacs = 1 OR HasHotPublicationsLeft = 1 OR HasCVDBAccess = 1 OR HasActivatedLogo = 1 OR HasActivatedProfile = 1 THEN '2.Из них есть доп.сервис'
    ELSE '9.Нет платного сервиса на счету'
   END
ORDER BY D.Fulldate, PaidGroup;
