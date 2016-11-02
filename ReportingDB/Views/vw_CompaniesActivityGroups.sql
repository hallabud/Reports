
CREATE VIEW [dbo].[vw_CompaniesActivityGroups]
 
 
AS

SELECT 
   DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.FullDate
 , CONVERT(VARCHAR, DD.FullDate, 104) AS 'FullDate104'
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
 , COUNT(DISTINCT Company_key) AS CompaniesNum
FROM dbo.FactCompanyStatuses CS
 JOIN dbo.DimDate DD ON CS.Date_key = DD.Date_key
WHERE PublicationsNumLast6Months IS NOT NULL AND WeekDayNum = 5
GROUP BY 
   DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.FullDate
 , CONVERT(VARCHAR, DD.FullDate, 104)
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