CREATE PROCEDURE dbo.usp_ssrs_Report_BoardMeetingDashboard_TotalSales1C 
	@YearNum INT, @Mode TINYINT 

AS

IF @Mode = 1
	
	BEGIN
		
		WITH C AS
		 (
		SELECT YearNum, AMMM.MonthNum, MonthNameEng, TotalSales_From1C
		 , LAG(TotalSales_From1C, 1, NULL) OVER(PARTITION BY AMMM.MonthNum ORDER BY YearNum) AS TotalSales_From1C_Prv
		 , 1. * TotalSales_From1C / LAG(TotalSales_From1C, 1, NULL) OVER(PARTITION BY AMMM.MonthNum ORDER BY YearNum) - 1 AS YTY
		FROM dbo.AggrManagementMetricsMonthly AMMM
		 JOIN (SELECT DISTINCT MonthNum, MonthNameEng FROM dbo.DimDate) MNTH ON AMMM.MonthNum = MNTH.MonthNum
		WHERE YearNum BETWEEN @YearNum - 1 AND @YearNum
		 )
		SELECT *
		FROM C 
		WHERE YTY IS NOT NULL
		ORDER BY YearNum, MonthNum;

	END

IF @Mode = 2

	BEGIN

		WITH C AS
		 (
		SELECT YearNum, AMMM.MonthNum, MonthNameEng, TotalSales_From1C
		 , LAG(TotalSales_From1C, 1, NULL) OVER(PARTITION BY AMMM.MonthNum ORDER BY YearNum) AS TotalSales_From1C_Prv
		 , 1. * TotalSales_From1C / LAG(TotalSales_From1C, 1, NULL) OVER(PARTITION BY AMMM.MonthNum ORDER BY YearNum) - 1 AS YTY
		 , ROW_NUMBER() OVER(ORDER BY YearNum DESC, AMMM.MonthNum DESC) AS RowNum
		FROM dbo.AggrManagementMetricsMonthly AMMM
		 JOIN (SELECT DISTINCT MonthNum, MonthNameEng FROM dbo.DimDate) MNTH ON AMMM.MonthNum = MNTH.MonthNum
		WHERE YearNum BETWEEN @YearNum - 2 AND @YearNum
		 )
		SELECT YearNum, MonthNum, MonthNameEng, TotalSales_From1C, TotalSales_From1C_Prv, YTY
		FROM C 
		WHERE RowNum BETWEEN 1 AND 12
		ORDER BY YearNum, MonthNum;

	END