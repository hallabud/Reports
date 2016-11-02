CREATE PROCEDURE [dbo].[usp_ssrs_Report_NewEmailsMonthly]

AS

SELECT
   DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , ES.ConversionPageID
 , CP.Name AS ConversionPage
 , COUNT(*) AS CntEmails
 , LAG(COUNT(*)) OVER(PARTITION BY CP.Name, DD.MonthNum ORDER BY DD.YearNum) AS CntEmailsPrvYear
FROM Analytics.dbo.EmailSource ES
 JOIN Reporting.dbo.DimDate DD ON CAST(ES.AddDate AS DATE) = DD.FullDate
 JOIN Analytics.dbo.Dir_ConversionPage CP ON ES.ConversionPageID = CP.ID
GROUP BY
   DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , ES.ConversionPageID
 , CP.Name
ORDER BY 
   ES.ConversionPageID
 , DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus;
