CREATE PROCEDURE [dbo].[usp_ssrs_Report_BoardMeetingDashboard_Revenue] 
	@YearNum INT, @Mode TINYINT

AS

IF @Mode = 1
BEGIN
	WITH C AS
	 (
	SELECT DD.YearNum, DD.MonthNum, DD.MonthNameEng, SUM(FRR.RecognizedRevenue) AS SumRR
	 , LAG(SUM(FRR.RecognizedRevenue), 1, 0) OVER(PARTITION BY DD.MonthNum ORDER BY DD.YearNum) AS SumRR_PrvYear
	 , SUM(FRR.RecognizedRevenue) / NULLIF((LAG(SUM(FRR.RecognizedRevenue), 1, 0) OVER(PARTITION BY DD.MonthNum ORDER BY DD.YearNum)),0) - 1 AS YTY
	FROM dbo.DimDate DD
	 LEFT JOIN dbo.FactRecognizedRevenue FRR ON DD.Date_key = FRR.Date_key
	WHERE DD.YearNum BETWEEN @YearNum - 1 AND @YearNum
	GROUP BY DD.YearNum, DD.MonthNum, DD.MonthNameEng
	 )
	SELECT * 
	FROM C
	WHERE SumRR_PrvYear <> 0
	ORDER BY YearNum, MonthNum
END

IF @Mode = 2

BEGIN
	DECLARE @StartDate DATE;

	IF @YearNum = YEAR(GETDATE())
		SET @StartDate = DATEADD(YEAR, -1, DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()))
	ELSE 
		SELECT @StartDate = MIN(FullDate) FROM Reporting.dbo.DimDate WHERE YearNum = @YearNum;
	
	DECLARE @EndDate DATE = CASE WHEN @YearNum = YEAR(GETDATE()) THEN GETDATE() ELSE DATEADD(DAY, -1, DATEADD(YEAR, 1, @StartDate)) END;

		
	SELECT DD.YearNum, DD.MonthNum, DD.MonthNameEng, SUM(FRR.RecognizedRevenue) AS SumRR
	 , (SELECT SUM(FRR0.RecognizedRevenue) FROM dbo.FactRecognizedRevenue FRR0 JOIN dbo.DimDate DD0 ON FRR0.Date_key = DD0.Date_key WHERE DD0.YearNum = DD.YearNum -1 AND DD0.MonthNum = DD.MonthNum) AS SumRR_PrvYear
	 , SUM(FRR.RecognizedRevenue) / (SELECT SUM(FRR0.RecognizedRevenue) FROM dbo.FactRecognizedRevenue FRR0 JOIN dbo.DimDate DD0 ON FRR0.Date_key = DD0.Date_key WHERE DD0.YearNum = DD.YearNum -1 AND DD0.MonthNum = DD.MonthNum) - 1 AS YTY
	FROM dbo.FactRecognizedRevenue FRR
	 JOIN dbo.DimDate DD ON FRR.Date_key = DD.Date_key
	WHERE DD.FullDate BETWEEN @StartDate AND @EndDate
	GROUP BY DD.YearNum, DD.MonthNum, DD.MonthNameEng
	ORDER BY DD.YearNum, DD.MonthNum
END