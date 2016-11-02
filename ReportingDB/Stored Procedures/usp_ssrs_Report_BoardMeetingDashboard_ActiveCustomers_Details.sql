
CREATE PROCEDURE [dbo].[usp_ssrs_Report_BoardMeetingDashboard_ActiveCustomers_Details]
	@YearNum INT, @Mode TINYINT 

AS

BEGIN

IF @Mode = 1

	BEGIN
		
		WITH C AS
		 (
		SELECT DD.YearNum, DD.MonthNum, DD.MonthNameEng
		 , CASE 
			WHEN EXISTS (SELECT * 
						 FROM dbo.FactRecognizedRevenueNotebook RRN 
						  JOIN dbo.DimDate DD0 ON RRN.Date_key = DD0.Date_key
						 WHERE DC.NotebookId = RRN.NotebookID
						  AND DD0.FullDate BETWEEN DATEADD(MONTH, -3, DD.FullDate) AND DD.FullDate) THEN 'Active 3'
			WHEN EXISTS (SELECT *
						 FROM dbo.FactCompanyStatuses FCS
						  JOIN dbo.DimDate DD0 ON FCS.Date_key = DD0.Date_key
						 WHERE FCS.Company_key = DC.Company_key
						  AND FCS.HasPaidServices = 1
						  AND DD0.FullDate BETWEEN  DATEADD(MONTH, -3, DD.FullDate) AND DD.FullDate) THEN 'Inactive'
			ELSE 'Under Risk'
		   END AS ActiveSubGroup
		 , DC.Company_key
		FROM dbo.DimCompany DC
		 CROSS JOIN dbo.DimDate DD
		WHERE EXISTS (SELECT * 
					  FROM dbo.FactRecognizedRevenueNotebook RRN 
					   JOIN dbo.DimDate DD0 ON RRN.Date_key = DD0.Date_key
					  WHERE DC.NotebookId = RRN.NotebookID
					   AND DD0.FullDate BETWEEN DATEADD(YEAR, -1, DD.FullDate) AND DD.FullDate)
		 AND DD.IsLastDayOfMonth = 1
		 AND DD.YearNum = @YearNum
		 AND DD.FullDate <= GETDATE()
		 )
		SELECT YearNum, MonthNum, MonthNameEng, ActiveSubGroup, COUNT(*) AS ActiveCustomerCount
		FROM C
		GROUP BY YearNum, MonthNum, MonthNameEng, ActiveSubGroup
		ORDER BY YearNum, MonthNum, ActiveSubGroup

	END

IF @Mode = 2
	
	BEGIN
		
		DECLARE @StartDate DATE;

		IF @YearNum = YEAR(GETDATE()) SET @StartDate = DATEADD(YEAR, -1, DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()))
		 ELSE SELECT @StartDate = MIN(FullDate) FROM Reporting.dbo.DimDate WHERE YearNum = @YearNum;
	
		DECLARE @EndDate DATE = CASE WHEN @YearNum = YEAR(GETDATE()) THEN GETDATE() ELSE DATEADD(DAY, -1, DATEADD(YEAR, 1, @StartDate)) END;

		WITH C AS
		 (
		SELECT DD.YearNum, DD.MonthNum, DD.MonthNameEng
		 , CASE 
			WHEN EXISTS (SELECT * 
						 FROM dbo.FactRecognizedRevenueNotebook RRN 
						  JOIN dbo.DimDate DD0 ON RRN.Date_key = DD0.Date_key
						 WHERE DC.NotebookId = RRN.NotebookID
						  AND DD0.FullDate BETWEEN DATEADD(MONTH, -3, DD.FullDate) AND DD.FullDate) THEN 'Active 3'
			WHEN EXISTS (SELECT *
						 FROM dbo.FactCompanyStatuses FCS
						  JOIN dbo.DimDate DD0 ON FCS.Date_key = DD0.Date_key
						 WHERE FCS.Company_key = DC.Company_key
						  AND FCS.HasPaidServices = 1
						  AND DD0.FullDate BETWEEN  DATEADD(MONTH, -3, DD.FullDate) AND DD.FullDate) THEN 'Inactive'
			ELSE 'Under Risk'
		   END AS ActiveSubGroup
		 , DC.Company_key
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
		 )
		SELECT YearNum, MonthNum, MonthNameEng, ActiveSubGroup, COUNT(*) AS ActiveCustomerCount
		FROM C
		GROUP BY YearNum, MonthNum, MonthNameEng, ActiveSubGroup
		ORDER BY YearNum, MonthNum, ActiveSubGroup
		
	END

END