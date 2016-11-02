CREATE PROCEDURE [dbo].[usp_ssrs_Report_ResumeCountRabotaVsWork]
 (@StartDate DATETIME, @EndDate DATETIME)

AS

WITH C AS
 (
SELECT 
   D.FullDate
 , D.YearNum
 , D.MonthNameRus
 , D.MonthNameEng
 , D.MonthNum
 , D.WeekName
 , D.WeekNum
 , CASE Type
    WHEN 4 THEN 'day'
	WHEN 5 THEN 'week'
	WHEN 6 THEN 'month'
	WHEN 7 THEN 'year'
   END AS Period
 , CASE Source
    WHEN 0 THEN 'rabota.ua'
	WHEN 1 THEN 'work.ua'
   END AS Website
 , Quantity
FROM SRV16.RabotaUA2.dbo.WorkVacancyResumeCount WVRC
 JOIN Reporting.dbo.DimDate D ON CAST(WVRC.Date AS DATE) = D.FullDate
WHERE WVRC.Type IN (4,5,6,7)
 AND WVRC.Date BETWEEN @StartDate AND @EndDate
 )
SELECT FullDate, YearNum, MonthNameRus, MonthNameEng, MonthNum, WeekName, WeekNum, Period, [rabota.ua], [work.ua]
FROM C
PIVOT
(
  SUM(Quantity)
  FOR Website IN ([rabota.ua],[work.ua])
) AS pvt;