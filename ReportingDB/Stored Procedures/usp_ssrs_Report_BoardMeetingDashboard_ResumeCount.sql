CREATE PROCEDURE [dbo].[usp_ssrs_Report_BoardMeetingDashboard_ResumeCount]
	@YearNum INT, @Mode TINYINT

AS

IF @Mode = 1

	BEGIN

		WITH C AS
		 (
		SELECT 
		   D.YearNum
		 , D.MonthNameEng
		 , D.MonthNum
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
		FROM Analytics.dbo.WorkVacancyResumeCount WVRC
		 JOIN Reporting.dbo.DimDate D ON CAST(WVRC.Date AS DATE) = D.FullDate
		WHERE WVRC.Type IN (4,5,6,7)
		 AND D.YearNum = @YearNum
		 AND D.IsLastDayOfMonth = 1
		 AND WVRC.Type = 7
		 )
		SELECT YearNum, MonthNameEng, MonthNum, Period, [rabota.ua], [work.ua]
		 , 1. * ([rabota.ua] - [work.ua]) / Reporting.dbo.fnGetMinimumOf2Values([rabota.ua], [work.ua]) AS Gap
		FROM C
		PIVOT
		(
		  SUM(Quantity)
		  FOR Website IN ([rabota.ua],[work.ua])
		) AS pvt
		ORDER BY YearNum, MonthNum;

	END;

IF @Mode = 2
	
	BEGIN

		WITH C AS
		 (
		SELECT 
		   D.YearNum
		 , D.MonthNameEng
		 , D.MonthNum
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
		FROM Analytics.dbo.WorkVacancyResumeCount WVRC
		 JOIN Reporting.dbo.DimDate D ON CAST(WVRC.Date AS DATE) = D.FullDate
		WHERE WVRC.Type IN (4,5,6,7)
		 AND D.YearNum BETWEEN @YearNum - 1 AND @YearNum
		 AND D.IsLastDayOfMonth = 1
		 AND WVRC.Type = 7
		 )
		, C2 AS
		 (
		SELECT YearNum, MonthNameEng, MonthNum, Period, [rabota.ua], [work.ua]
		 , 1. * ([rabota.ua] - [work.ua]) / Reporting.dbo.fnGetMinimumOf2Values([rabota.ua], [work.ua]) AS Gap
		 , ROW_NUMBER() OVER(ORDER BY YearNum DESC, MonthNum DESC) AS RowNum
		FROM C
		PIVOT
		(
		  SUM(Quantity)
		  FOR Website IN ([rabota.ua],[work.ua])
		) AS pvt
		 )
		SELECT * 
		FROM C2 
		WHERE RowNum BETWEEN 1 AND 12
		ORDER BY YearNum, MonthNum;

	END;