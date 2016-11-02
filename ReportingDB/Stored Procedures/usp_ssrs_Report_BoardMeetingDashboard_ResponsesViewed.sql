CREATE PROCEDURE [dbo].[usp_ssrs_Report_BoardMeetingDashboard_ResponsesViewed]
	@YearNum INT, @Mode TINYINT

AS

IF @Mode = 1

	BEGIN
		
		WITH C AS
		 (
		SELECT YearNum, AMMM.MonthNum, M.MonthNameEng, AMMM.ResponsesNum, AMMM.ResponsesNum_Viewed, AMMM.ResponsesNum - AMMM.ResponsesNum_Viewed AS ResponsesNum_Notviewed, 1. * AMMM.ResponsesNum_Viewed / AMMM.ResponsesNum AS RespViewRate
		 , LAG(AMMM.ResponsesNum,1,NULL) OVER(PARTITION BY AMMM.MonthNum ORDER BY YearNum) AS ResponsesNum_Prv
		 , 1. * AMMM.ResponsesNum / LAG(AMMM.ResponsesNum,1,NULL) OVER(PARTITION BY AMMM.MonthNum ORDER BY YearNum) - 1 AS YTY
		FROM AggrManagementMetricsMonthly AMMM
		 JOIN (SELECT DISTINCT MonthNum, MonthNameEng FROM DimDate) M ON AMMM.MonthNum = M.MonthNum
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
		SELECT YearNum, AMMM.MonthNum, M.MonthNameEng, AMMM.ResponsesNum, AMMM.ResponsesNum_Viewed, AMMM.ResponsesNum - AMMM.ResponsesNum_Viewed AS ResponsesNum_Notviewed, 1. * AMMM.ResponsesNum_Viewed / AMMM.ResponsesNum AS RespViewRate
		 , LAG(AMMM.ResponsesNum,1,NULL) OVER(PARTITION BY AMMM.MonthNum ORDER BY YearNum) AS ResponsesNum_Prv
		 , 1. * AMMM.ResponsesNum / LAG(AMMM.ResponsesNum,1,NULL) OVER(PARTITION BY AMMM.MonthNum ORDER BY YearNum) - 1 AS YTY
		 , ROW_NUMBER() OVER(ORDER BY YearNum DESC, AMMM.MonthNum DESC) AS RowNum
		FROM AggrManagementMetricsMonthly AMMM
		 JOIN (SELECT DISTINCT MonthNum, MonthNameEng FROM DimDate) M ON AMMM.MonthNum = M.MonthNum
		WHERE YearNum BETWEEN @YearNum - 2 AND @YearNum
		 )
		SELECT YearNum, MonthNum, MonthNameEng, ResponsesNum, ResponsesNum_Viewed, ResponsesNum_Notviewed, RespViewRate, ResponsesNum_Prv, YTY
		FROM C
		WHERE RowNum BETWEEN 1 AND 12
		ORDER BY YearNum, MonthNum;

	END