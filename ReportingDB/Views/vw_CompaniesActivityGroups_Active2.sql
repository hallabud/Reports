
CREATE VIEW [dbo].[vw_CompaniesActivityGroups_Active2]
 
 
AS

SELECT 
   DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.FullDate
 , DD.DayNum
 , DD.WeekDayNum
 , IsMegaChecked
 , MonthsFromRegDate
 , CASE 
    WHEN (HasPaidPublishedVacs = 1 OR HasPaidPublicationsLeft = 1 OR HasHotPublishedVacs = 1 OR HasHotPublicationsLeft = 1 
		  OR HasCVDBAccess = 1 OR HasActivatedLogo = 1 OR HasActivatedProfile = 1) THEN 1
    ELSE 0
   END AS 'HasPaidServices'
 , CASE 
    WHEN PublicationsNumLast2Months >= 2 AND MonthsNumLast2Months >= 2
     THEN 1
    ELSE 0
   END AS 'IsActive2' 
 , Company_key
FROM dbo.FactCompanyStatuses CS
 JOIN dbo.DimDate DD ON CS.Date_key = DD.Date_key
--WHERE PublicationsNumLast6Months IS NOT NULL --AND WeekDayNum = 5;