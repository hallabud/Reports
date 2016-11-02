


CREATE VIEW [dbo].[vw_CompaniesActivityGroupsMonthly]
 
AS

SELECT 
   DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.FullDate
 , CONVERT(VARCHAR, DD.FullDate, 104) AS 'RealFullDate104'
 , CONVERT(VARCHAR, DATEADD(DAY, -1, DD.FullDate), 104) AS 'FullDate104'
 , CASE WHEN M.DepartmentID = 2 THEN 1 ELSE 0 END AS 'IsSalesForce' 
 , NC.IsLegalPerson
 , IsMegaChecked
 , CASE 
    WHEN (HasPaidPublishedVacs = 1 OR HasPaidPublicationsLeft = 1 OR HasHotPublishedVacs = 1 OR HasHotPublicationsLeft = 1 
		  OR HasCVDBAccess = 1 OR HasActivatedLogo = 1 OR HasActivatedProfile = 1) THEN 1
    ELSE 0
   END AS 'HasPaidServices'
 , CASE 
    WHEN PublicationsNumLast6Months >= 2 AND MonthsNumLast6Months >= 2 AND PublicationsNumLast3Months >= 1
     THEN 1
    ELSE 0
   END AS 'IsActive6'
 , CASE 
    WHEN PublicationsNumLast3Months >= 2 AND MonthsNumLast3Months >= 2
     THEN 1
    ELSE 0
   END AS 'IsActive3' 
 , CASE 
    WHEN PublicationsNumLast2Months >= 2 AND MonthsNumLast2Months >= 2
     THEN 1
    ELSE 0
   END AS 'IsActive2' 
 , COUNT(DISTINCT CS.Company_key) AS CompaniesNum
FROM Reporting.dbo.FactCompanyStatuses CS
 JOIN Reporting.dbo.DimDate DD ON CS.Date_key = DD.Date_key
 JOIN Reporting.dbo.DimCompany DC ON CS.Company_key = DC.Company_key
 JOIN Analytics.dbo.NotebookCompany NC ON DC.NotebookId = NC.NotebookId
 JOIN Analytics.dbo.Manager M ON NC.ManagerID = M.Id
WHERE PublicationsNumLast6Months IS NOT NULL AND DayNum = 1
GROUP BY 
   DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.FullDate
 , CONVERT(VARCHAR, DD.FullDate, 104)
 , CONVERT(VARCHAR, DATEADD(DAY, -1, DD.FullDate), 104)
 , CASE WHEN M.DepartmentID = 2 THEN 1 ELSE 0 END
 , NC.IsLegalPerson
 , IsMegaChecked
 , CASE 
    WHEN (HasPaidPublishedVacs = 1 OR HasPaidPublicationsLeft = 1 OR HasHotPublishedVacs = 1 OR HasHotPublicationsLeft = 1 
		  OR HasCVDBAccess = 1 OR HasActivatedLogo = 1 OR HasActivatedProfile = 1) THEN 1
    ELSE 0
   END
 , CASE 
    WHEN PublicationsNumLast6Months >= 2 AND MonthsNumLast6Months >= 2 AND PublicationsNumLast3Months >= 1
     THEN 1
    ELSE 0
   END
 , CASE 
    WHEN PublicationsNumLast3Months >= 2 AND MonthsNumLast3Months >= 2
     THEN 1
    ELSE 0
   END
 , CASE 
    WHEN PublicationsNumLast2Months >= 2 AND MonthsNumLast2Months >= 2
     THEN 1
    ELSE 0
   END;

