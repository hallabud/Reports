
CREATE PROCEDURE [dbo].[usp_ssrs_Report_NewEmailsWeekly]
	@RowNum INT

AS

SET DATEFIRST 1;

WITH C AS
 (
SELECT
   DD.YearNum
 , DD.WeekNum
 , DD.WeekName
 , ES.ConversionPageID
 , CP.Name AS ConversionPage
 , COUNT(*) AS CntEmails
 , ROW_NUMBER() OVER(PARTITION BY ES.ConversionPageID ORDER BY YearNum DESC, WeekNum DESC) AS RowNum
FROM Analytics.dbo.EmailSource ES
 JOIN Reporting.dbo.DimDate DD ON CAST(ES.AddDate AS DATE) = DD.FullDate
 JOIN Analytics.dbo.Dir_ConversionPage CP ON ES.ConversionPageID = CP.ID
WHERE ES.AddDate < DATEADD(DAY, 1 - DATEPART(WEEKDAY, CAST(GETDATE() AS DATE)), CAST(GETDATE() AS DATE))
 AND ES.AddDate >= DATEADD(WEEK, -14, DATEADD(DAY, 1 - DATEPART(WEEKDAY, CAST(GETDATE() AS DATE)), CAST(GETDATE() AS DATE)))
GROUP BY
   DD.YearNum
 , DD.WeekNum
 , DD.WeekName
 , ES.ConversionPageID
 , CP.Name
 )
SELECT *
FROM C
WHERE RowNum <= @RowNum