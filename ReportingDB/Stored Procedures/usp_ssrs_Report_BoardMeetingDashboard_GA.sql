CREATE PROCEDURE [dbo].[usp_ssrs_Report_BoardMeetingDashboard_GA]
	@YearNum INT, @Mode TINYINT 

AS

IF @Mode = 1
	
	BEGIN
		
		WITH C AS
		 (
		SELECT FIM.YearNum, FIM.MonthNum, D.MonthNameEng, LI.IndexName, FIM.Value AS IndexValue
		 , LAG(FIM.Value, 1, NULL) OVER(PARTITION BY LI.IndexName, FIM.MonthNum ORDER BY FIM.YearNum) AS IndexValue_Prv
		 , 1. * FIM.Value / LAG(FIM.Value, 1, NULL) OVER(PARTITION BY LI.IndexName, FIM.MonthNum ORDER BY FIM.YearNum) - 1. AS YTY
		FROM Reporting.dbo.GA_Fact_Indexes_Monthly FIM
		 JOIN Reporting.dbo.GA_Lookup_Indexes LI ON FIM.IndexID = LI.ID
		 JOIN (SELECT DISTINCT MonthNum, MonthNameEng FROM Reporting.dbo.DimDate D WHERE D.YearNum = @YearNum) D ON FIM.MonthNum = D.MonthNum
		WHERE FIM.YearNum BETWEEN @YearNum - 1 AND @YearNum
		 )
		SELECT YearNum, MonthNum, MonthNameEng, IndexName, IndexValue, IndexValue_Prv, YTY
		FROM C
		WHERE YTY IS NOT NULL

		
	END

IF @Mode = 2

	BEGIN

		WITH C AS
		 (
		SELECT FIM.YearNum, FIM.MonthNum, D.MonthNameEng, LI.IndexName, FIM.Value AS IndexValue
		 , LAG(FIM.Value, 1, NULL) OVER(PARTITION BY LI.IndexName, FIM.MonthNum ORDER BY FIM.YearNum) AS IndexValue_Prv
		 , 1. * FIM.Value / LAG(FIM.Value, 1, NULL) OVER(PARTITION BY LI.IndexName, FIM.MonthNum ORDER BY FIM.YearNum) - 1. AS YTY
		 , ROW_NUMBER() OVER(PARTITION BY LI.IndexName ORDER BY FIM.YearNum DESC, FIM.MonthNum DESC)  AS RowNum
		FROM Reporting.dbo.GA_Fact_Indexes_Monthly FIM
		 JOIN Reporting.dbo.GA_Lookup_Indexes LI ON FIM.IndexID = LI.ID
		 JOIN (SELECT DISTINCT MonthNum, MonthNameEng FROM Reporting.dbo.DimDate D WHERE D.YearNum = @YearNum) D ON FIM.MonthNum = D.MonthNum
		WHERE FIM.YearNum BETWEEN @YearNum - 2 AND @YearNum
		 )
		SELECT YearNum, MonthNum, MonthNameEng, IndexName, IndexValue, IndexValue_Prv, YTY, RowNum
		FROM C
		WHERE RowNum BETWEEN 1 AND 12

	END