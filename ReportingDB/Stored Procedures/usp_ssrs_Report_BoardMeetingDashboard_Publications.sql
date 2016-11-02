
CREATE PROCEDURE [dbo].[usp_ssrs_Report_BoardMeetingDashboard_Publications]
	@YearNum INT, @Mode TINYINT 

AS

IF @Mode = 1
BEGIN
	WITH C AS
	 (
	SELECT
	   YEAR(NCS.AddDate) AS YearNum
	 , DATEPART(MONTH, NCS.AddDate) AS MonthNum
	 , DATENAME(MONTH, NCS.AddDate) AS MonthNameEng
	 , SUM(NCS.SpendCount) AS PubsSpent
	 , LAG(SUM(NCS.SpendCount),1,NULL) OVER(PARTITION BY DATEPART(MONTH, NCS.AddDate) ORDER BY YEAR(NCS.AddDate)) AS PubsSpent_Prv
	 , 1. * SUM(NCS.SpendCount) / LAG(SUM(NCS.SpendCount),1,NULL) OVER(PARTITION BY DATEPART(MONTH, NCS.AddDate) ORDER BY YEAR(NCS.AddDate)) - 1. AS YTY
	FROM Analytics.dbo.NotebookCompany_Spent NCS
	 LEFT JOIN Analytics.dbo.TicketPayment TP ON NCS.TicketPaymentID = TP.Id AND NCS.RegionalPackageID IS NULL
	 LEFT JOIN Analytics.dbo.RegionalTicketPayment RTP ON NCS.TicketPaymentID = RTP.ID AND NCS.RegionalPackageID IS NOT NULL
	WHERE YEAR(NCS.AddDate) BETWEEN @YearNum - 1 AND @YearNum
	 AND COALESCE(TP.TicketPaymentTypeID, RTP.TicketPaymentTypeID) IN (1,2,3,4)
	 AND NCS.SpendType <> 5
	GROUP BY 
	   YEAR(NCS.AddDate)
	 , DATEPART(MONTH, NCS.AddDate)
	 , DATENAME(MONTH, NCS.AddDate)
	  )
	SELECT * 
	FROM C
	WHERE YTY IS NOT NULL
	ORDER BY YearNum, MonthNum;

END

IF @Mode = 2
BEGIN

	DECLARE @StartDate DATE;
	
	IF @YearNum = YEAR(GETDATE())
		SET @StartDate = DATEADD(YEAR, -2, DATEADD(DAY, 1 - DAY(GETDATE()), GETDATE()))
	ELSE 
		SELECT @StartDate = MIN(FullDate) FROM Reporting.dbo.DimDate WHERE YearNum = @YearNum - 1;
	
	DECLARE @EndDate DATE = CASE 
							 WHEN @YearNum = YEAR(GETDATE()) THEN GETDATE() 
							 ELSE DATEADD(DAY, -1, DATEADD(YEAR, 2, @StartDate))
							END;

	WITH C AS
	 (
	SELECT
	   YEAR(NCS.AddDate) AS YearNum
	 , DATEPART(MONTH, NCS.AddDate) AS MonthNum
	 , DATENAME(MONTH, NCS.AddDate) AS MonthNameEng
	 , SUM(NCS.SpendCount) AS PubsSpent
	 , LAG(SUM(NCS.SpendCount),1,NULL) OVER(PARTITION BY DATEPART(MONTH, NCS.AddDate) ORDER BY YEAR(NCS.AddDate)) AS PubsSpent_Prv
	 , 1. * SUM(NCS.SpendCount) / LAG(SUM(NCS.SpendCount),1,NULL) OVER(PARTITION BY DATEPART(MONTH, NCS.AddDate) ORDER BY YEAR(NCS.AddDate)) - 1. AS YTY
	FROM Analytics.dbo.NotebookCompany_Spent NCS
	 LEFT JOIN Analytics.dbo.TicketPayment TP ON NCS.TicketPaymentID = TP.Id AND NCS.RegionalPackageID IS NULL
	 LEFT JOIN Analytics.dbo.RegionalTicketPayment RTP ON NCS.TicketPaymentID = RTP.ID AND NCS.RegionalPackageID IS NOT NULL
	WHERE NCS.AddDate BETWEEN @StartDate AND DATEADD(DAY, 1, @EndDate)
	 AND COALESCE(TP.TicketPaymentTypeID, RTP.TicketPaymentTypeID) IN (1,2,3,4)
	 AND NCS.SpendType <> 5
	GROUP BY 
	   YEAR(NCS.AddDate)
	 , DATEPART(MONTH, NCS.AddDate)
	 , DATENAME(MONTH, NCS.AddDate)
	 )
	SELECT *
	FROM C
	WHERE YTY IS NOT NULL
	ORDER BY YearNum, MonthNum;

END