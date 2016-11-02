CREATE PROCEDURE [dbo].[usp_ssrs_Report_BoardMeetingDashboard_VacancyCount]
	@YearNum INT, @Mode TINYINT

AS

IF @Mode =1

	BEGIN

		WITH C AS
		 (
		SELECT D.YearNum, D.MonthNum, D.MonthNameEng
		 , CASE Source WHEN 0 THEN 'rabota.ua' ELSE 'work.ua' END AS Website
		 , AVG(VCBC.VacancyCount) AS VacancyCount
		FROM Analytics.dbo.Spider2VacancyCountByCity VCBC
		 JOIN Reporting.dbo.DimDate D ON Analytics.dbo.fnGetDatePart(VCBC.AddDate) = D.FullDate 
		WHERE VCBC.CityID = 0 AND D.YearNum = @YearNum
		GROUP BY D.YearNum, D.MonthNum, D.MonthNameEng, VCBC.Source
		 )
		SELECT YearNum, MonthNum, MonthNameEng, [rabota.ua] AS rabotaua, [work.ua] AS workua, 1. * ([rabota.ua] - [work.ua]) / Reporting.dbo.fnGetMinimumOf2Values ([rabota.ua], [work.ua]) AS Gap
		FROM C
		PIVOT
		(SUM(VacancyCount)
		 FOR Website IN ([rabota.ua],[work.ua])
		) AS pvt
		ORDER BY YearNum, MonthNum;

	END

IF @Mode = 2
	
	BEGIN

		WITH C AS
		 (
		SELECT D.YearNum, D.MonthNum, D.MonthNameEng
		 , CASE Source WHEN 0 THEN 'rabota.ua' ELSE 'work.ua' END AS Website
		 , AVG(VCBC.VacancyCount) AS VacancyCount
		FROM Analytics.dbo.Spider2VacancyCountByCity VCBC
		 JOIN Reporting.dbo.DimDate D ON Analytics.dbo.fnGetDatePart(VCBC.AddDate) = D.FullDate 
		WHERE VCBC.CityID = 0 AND D.YearNum BETWEEN @YearNum - 1 AND @YearNum
		GROUP BY D.YearNum, D.MonthNum, D.MonthNameEng, VCBC.Source
		 )
		 , C2 AS
		 (
		SELECT YearNum, MonthNum, MonthNameEng, [rabota.ua] AS rabotaua, [work.ua] AS workua, 1. * ([rabota.ua] - [work.ua]) / Reporting.dbo.fnGetMinimumOf2Values ([rabota.ua], [work.ua]) AS Gap
		 , ROW_NUMBER() OVER(ORDER BY YearNum DESC, MonthNum DESC) AS RowNum
		FROM C
		PIVOT
		(SUM(VacancyCount)
		 FOR Website IN ([rabota.ua],[work.ua])
		) AS pvt
		 )
		SELECT * 
		FROM C2
		WHERE RowNum BETWEEN 1 AND 12
		ORDER BY YearNum, MonthNum;

	END