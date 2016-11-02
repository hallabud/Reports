

CREATE PROCEDURE dbo.usp_ssrs_Report_BoardMeetingDashboard_ActiveCustomers
	@YearNum INT, @Mode TINYINT 

AS

BEGIN

IF @Mode = 1

	BEGIN
		
		WITH C AS
		 (		
		SELECT DD.YearNum, DD.MonthNum, DD.MonthNameEng
		 , COUNT(*) AS ActiveCustomers
		 , LAG(COUNT(*),1) OVER(PARTITION BY DD.MonthNum ORDER BY DD.YearNum) AS ActiveCustomers_Prv
		 , 1. * COUNT(*) / LAG(COUNT(*),1) OVER(PARTITION BY DD.MonthNum ORDER BY DD.YearNum) - 1. AS YoY
		FROM dbo.DimCompany DC
		 CROSS JOIN dbo.DimDate DD
		WHERE EXISTS (SELECT * 
					  FROM dbo.FactRecognizedRevenueNotebook RRN 
					   JOIN dbo.DimDate DD0 ON RRN.Date_key = DD0.Date_key
					  WHERE DC.NotebookId = RRN.NotebookID
					   AND DD0.FullDate BETWEEN DATEADD(YEAR, -1, DD.FullDate) AND DD.FullDate)
		 AND DD.IsLastDayOfMonth = 1
		 AND DD.YearNum BETWEEN @YearNum - 1 AND @YearNum
		 AND DD.FullDate <= GETDATE()
		GROUP BY DD.YearNum, DD.MonthNum, DD.MonthNameEng
		 )
		SELECT * 
		FROM C
		WHERE ActiveCustomers_Prv IS NOT NULL
		ORDER BY YearNum, MonthNum

	END

IF @Mode = 2
	
	BEGIN
		
		DECLARE @StartDate DATE;

		IF @YearNum = YEAR(GETDATE()) SET @StartDate = DATEADD(YEAR, -2, DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()))
		 ELSE SELECT @StartDate = MIN(FullDate) FROM Reporting.dbo.DimDate WHERE YearNum = @YearNum - 1;
	
		DECLARE @EndDate DATE = CASE WHEN @YearNum = YEAR(GETDATE()) THEN GETDATE() ELSE DATEADD(DAY, -1, DATEADD(YEAR, 2, @StartDate)) END;

		WITH C AS
		 (
		SELECT DD.YearNum, DD.MonthNum, DD.MonthNameEng
		 , COUNT(*) AS ActiveCustomers
		 , LAG(COUNT(*),1) OVER(PARTITION BY DD.MonthNum ORDER BY DD.YearNum) AS ActiveCustomers_Prv
		 , 1. * COUNT(*) / LAG(COUNT(*),1) OVER(PARTITION BY DD.MonthNum ORDER BY DD.YearNum) - 1. AS YoY
		FROM dbo.DimCompany DC
		 CROSS JOIN dbo.DimDate DD
		WHERE EXISTS (SELECT * 
					  FROM dbo.FactRecognizedRevenueNotebook RRN 
					   JOIN dbo.DimDate DD0 ON RRN.Date_key = DD0.Date_key
					  WHERE DC.NotebookId = RRN.NotebookID
					   AND DD0.FullDate BETWEEN DATEADD(YEAR, -1, DD.FullDate) AND DD.FullDate)
		 AND DD.IsLastDayOfMonth = 1
		 AND DD.FullDate BETWEEN @StartDate AND @EndDate
		 AND DD.FullDate <= GETDATE()
		GROUP BY DD.YearNum, DD.MonthNum, DD.MonthNameEng
		 )
		SELECT * 
		FROM C
		WHERE ActiveCustomers_Prv IS NOT NULL
		ORDER BY YearNum, MonthNum

	END

END