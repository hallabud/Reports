

CREATE VIEW [dbo].[vw_CompaniesActivityGroups_Active3]
  
AS

SELECT 
   DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.FullDate
 , DD.DayNum
 , DD.WeekDayNum
 , DD.IsLastDayOfMonth
 , IsMegaChecked
 , MonthsFromRegDate
 , CASE 
    WHEN (HasPaidPublishedVacs = 1 OR HasPaidPublicationsLeft = 1 OR HasHotPublishedVacs = 1 OR HasHotPublicationsLeft = 1 
		  OR HasCVDBAccess = 1 OR HasActivatedLogo = 1 OR HasActivatedProfile = 1) THEN 1
    ELSE 0
   END AS 'HasPaidServices'
 , CS.Company_key
 , DC.NotebookID
FROM dbo.FactCompanyStatuses CS
 JOIN dbo.DimDate DD ON CS.Date_key = DD.Date_key
 JOIN dbo.DimCompany DC ON CS.Company_key = DC.Company_key
WHERE PublicationsNumLast3Months >= 2 AND MonthsNumLast3Months >= 2
--WHERE PublicationsNumLast6Months IS NOT NULL --AND WeekDayNum = 5;
