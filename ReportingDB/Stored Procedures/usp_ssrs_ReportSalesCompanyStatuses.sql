
CREATE PROCEDURE dbo.usp_ssrs_ReportSalesCompanyStatuses
 (@StartDate DATETIME, @EndDate DATETIME)

AS

--DECLARE @StartDate DATETIME; SET @StartDate = '2013-04-01'
--DECLARE @EndDate DATETIME; SET @EndDate = '2013-04-30'

SELECT 
   DD.FullDate
 , DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.WeekNum
 , DD.WeekName
 , DD.WeekDayNum
 , DD.WeekDayNameRus
 , DD.IsLastDayOfMonth
 , Rating
 , IsMegaChecked
 , IsPriority2013
 , HasPaidPublishedVacs
 , HasPaidPublicationsLeft
 , HasHotPublishedVacs
 , HasHotPublicationsLeft
 , HasCVDBAccess
 , HasActivatedLogo
 , HasActivatedProfile
 , COUNT(*) AS 'NumberOfCompanies'
FROM dbo.FactCompanyStatuses FCS
 JOIN dbo.DimDate DD ON FCS.Date_key = DD.Date_key
WHERE DD.FullDate BETWEEN @StartDate AND @EndDate
GROUP BY  
   DD.FullDate
 , DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.WeekNum
 , DD.WeekName
 , DD.WeekDayNum
 , DD.WeekDayNameRus
 , DD.IsLastDayOfMonth
 , Rating
 , IsMegaChecked
 , IsPriority2013
 , HasPaidPublishedVacs
 , HasPaidPublicationsLeft
 , HasHotPublishedVacs
 , HasHotPublicationsLeft
 , HasCVDBAccess
 , HasActivatedLogo
 , HasActivatedProfile;