CREATE PROCEDURE [dbo].[usp_ssrs_Report_BoardMeetingDashboard_Responsers]
	@YearNum INT, @Mode TINYINT

AS

IF @Mode = 1
	
	BEGIN
		
		WITH C AS
		 (
		SELECT 
		   FR.YearNum AS RespYear
		 , FR.MonthNum AS RespMonthNum
		 , M.MonthNameEng AS RespMonthName
		 , FR.ResponsersNum AS EmailsNum
		 , LAG(FR.ResponsersNum,1,NULL) OVER(PARTITION BY FR.MonthNum ORDER BY FR.YearNum) AS EmailsNum_Prv
		 , 1. * FR.ResponsersNum / LAG(FR.ResponsersNum,1,NULL) OVER(PARTITION BY FR.MonthNum ORDER BY FR.YearNum) - 1 AS YTY
		 , ROW_NUMBER() OVER(ORDER BY FR.YearNum DESC, FR.MonthNum DESC) AS RowNum
		FROM Reporting.dbo.FactResponsers FR
		 JOIN (SELECT DISTINCT MonthNum, MonthNameEng FROM Reporting.dbo.DimDate) M ON FR.MonthNum = M.MonthNum
		WHERE FR.YearNum BETWEEN @YearNum - 1 AND @YearNum
		 )
		SELECT *
		FROM C
		WHERE YTY IS NOT NULL
		ORDER BY RespYear, RespMonthNum

	END

IF @Mode = 2
	
	BEGIN
		
		WITH C AS
		 (
		SELECT 
		   FR.YearNum AS RespYear
		 , FR.MonthNum AS RespMonthNum
		 , M.MonthNameEng AS RespMonthName
		 , FR.ResponsersNum AS EmailsNum
		 , LAG(FR.ResponsersNum,1,NULL) OVER(PARTITION BY FR.MonthNum ORDER BY FR.YearNum) AS EmailsNum_Prv
		 , 1. * FR.ResponsersNum / LAG(FR.ResponsersNum,1,NULL) OVER(PARTITION BY FR.MonthNum ORDER BY FR.YearNum) - 1 AS YTY
		 , ROW_NUMBER() OVER(ORDER BY FR.YearNum DESC, FR.MonthNum DESC) AS RowNum
		FROM Reporting.dbo.FactResponsers FR
		 JOIN (SELECT DISTINCT MonthNum, MonthNameEng FROM Reporting.dbo.DimDate) M ON FR.MonthNum = M.MonthNum
		WHERE FR.YearNum BETWEEN @YearNum - 2 AND @YearNum
		 )
		SELECT *
		FROM C
		WHERE RowNum BETWEEN 1 AND 12
		ORDER BY RespYear, RespMonthNum

	END

	