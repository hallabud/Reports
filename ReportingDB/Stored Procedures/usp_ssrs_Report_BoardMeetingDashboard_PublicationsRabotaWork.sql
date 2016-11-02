CREATE PROCEDURE [dbo].[usp_ssrs_Report_BoardMeetingDashboard_PublicationsRabotaWork]
	@YearNum INT, @Mode TINYINT

AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

IF @Mode = 1
	
	BEGIN

	SELECT
	  'rabota.ua' AS Website
	 , 'Total' AS SpentGroup
     , YEAR(NCS.AddDate) AS YearNum
     , DATEPART(MONTH, NCS.AddDate) AS MonthNum
     , DATENAME(MONTH, NCS.AddDate) AS MonthNameEng
     , SUM(NCS.SpendCount) AS PubsSpent
    FROM Analytics.dbo.NotebookCompany_Spent NCS
	 JOIN Reporting.dbo.DimDate D ON CONVERT(DATE, NCS.AddDate) = D.FullDate
     LEFT JOIN Analytics.dbo.TicketPayment TP ON NCS.TicketPaymentID = TP.Id AND NCS.RegionalPackageID IS NULL
     LEFT JOIN Analytics.dbo.RegionalTicketPayment RTP ON NCS.TicketPaymentID = RTP.ID AND NCS.RegionalPackageID IS NOT NULL
    WHERE D.YearNum = @YearNum
	 AND COALESCE(TP.TicketPaymentTypeID, RTP.TicketPaymentTypeID) IN (1,2,3,4)
	 AND NCS.SpendType <> 5
	GROUP BY 
      YEAR(NCS.AddDate)
	, DATEPART(MONTH, NCS.AddDate)
    , DATENAME(MONTH, NCS.AddDate)

	UNION ALL

	SELECT 
	   'work.ua' AS Website
	 , 'Business Placement' AS SpentGroup
	 , D0.YearNum, D0.MonthNum, D0.MonthNameEng
	 , SUM(CASE WHEN FSCI.VacancyCount > 3 THEN 3 ELSE FSCI.VacancyCount END) AS PubsSpent
	FROM Reporting.dbo.FactSpiderCompanyIndexes FSCI WITH (NOLOCK)
	 JOIN Reporting.dbo.DimDate D ON FSCI.Date_key = D.Date_key
	 JOIN Reporting.dbo.DimDate D0 ON FSCI.Date_key - 1 = D0.Date_key
	WHERE D.DayNum = 1
	 AND ((FSCI.IsBusiness = 1 AND FSCI.VacancyCount > 3) OR (FSCI.IsBusiness = 0 AND FSCI.VacancyCount > 1))
	 AND D0.YearNum = @YearNum
	GROUP BY D0.YearNum, D0.MonthNum, D0.MonthNameEng

	UNION ALL

	SELECT 
	   'work.ua' AS Website
	 , 'Business Placement + Paid' AS SpentGroup
	 , D0.YearNum, D0.MonthNum, D0.MonthNameEng
	 , SUM(FSCI.VacancyCount)
	FROM Reporting.dbo.FactSpiderCompanyIndexes FSCI WITH (NOLOCK)
	 JOIN Reporting.dbo.DimDate D ON FSCI.Date_key = D.Date_key
	 JOIN Reporting.dbo.DimDate D0 ON FSCI.Date_key - 1 = D0.Date_key
	WHERE D.DayNum = 1
	 AND ((FSCI.IsBusiness = 1 AND FSCI.VacancyCount > 3) OR (FSCI.IsBusiness = 0 AND FSCI.VacancyCount > 1))
	 AND D0.YearNum = @YearNum
	GROUP BY D0.YearNum, D0.MonthNum, D0.MonthNameEng

	ORDER BY Website, YearNum, MonthNum;

	END

IF @Mode = 2

	BEGIN


	WITH C AS
	 (
	SELECT
	  'rabota.ua' AS Website
	 , 'Total' AS SpentGroup
     , YEAR(NCS.AddDate) AS YearNum
     , DATEPART(MONTH, NCS.AddDate) AS MonthNum
     , DATENAME(MONTH, NCS.AddDate) AS MonthNameEng
     , SUM(NCS.SpendCount) AS PubsSpent
	 , ROW_NUMBER() OVER(ORDER BY YEAR(NCS.AddDate) DESC, DATEPART(MONTH, NCS.AddDate) DESC) AS RowNum
    FROM Analytics.dbo.NotebookCompany_Spent NCS
	 JOIN Reporting.dbo.DimDate D ON CONVERT(DATE, NCS.AddDate) = D.FullDate
     LEFT JOIN Analytics.dbo.TicketPayment TP ON NCS.TicketPaymentID = TP.Id AND NCS.RegionalPackageID IS NULL
     LEFT JOIN Analytics.dbo.RegionalTicketPayment RTP ON NCS.TicketPaymentID = RTP.ID AND NCS.RegionalPackageID IS NOT NULL
    WHERE D.YearNum BETWEEN @YearNum - 1 AND @YearNum
	 AND COALESCE(TP.TicketPaymentTypeID, RTP.TicketPaymentTypeID) IN (1,2,3,4)
	 AND NCS.SpendType <> 5
	GROUP BY 
      YEAR(NCS.AddDate)
	, DATEPART(MONTH, NCS.AddDate)
    , DATENAME(MONTH, NCS.AddDate)

	UNION ALL

	SELECT 
	   'work.ua' AS Website
	 , 'Business Placement' AS SpentGroup
	 , D0.YearNum, D0.MonthNum, D0.MonthNameEng
	 , SUM(CASE WHEN FSCI.VacancyCount > 3 THEN 3 ELSE FSCI.VacancyCount END) AS PubsSpent
	 , ROW_NUMBER() OVER(ORDER BY D0.YearNum DESC, D0.MonthNum DESC) AS RowNum
	FROM Reporting.dbo.FactSpiderCompanyIndexes FSCI WITH (NOLOCK)
	 JOIN Reporting.dbo.DimDate D ON FSCI.Date_key = D.Date_key
	 JOIN Reporting.dbo.DimDate D0 ON FSCI.Date_key - 1 = D0.Date_key
	WHERE D.DayNum = 1
	 AND ((FSCI.IsBusiness = 1 AND FSCI.VacancyCount > 3) OR (FSCI.IsBusiness = 0 AND FSCI.VacancyCount > 1))
	 AND D0.YearNum BETWEEN @YearNum - 1 AND @YearNum
	GROUP BY D0.YearNum, D0.MonthNum, D0.MonthNameEng

	UNION ALL

	SELECT 
	   'work.ua' AS Website
	 , 'Business Placement + Paid' AS SpentGroup
	 , D0.YearNum, D0.MonthNum, D0.MonthNameEng
	 , SUM(FSCI.VacancyCount)
	 , ROW_NUMBER() OVER(ORDER BY D0.YearNum DESC, D0.MonthNum DESC) AS RowNum
	FROM Reporting.dbo.FactSpiderCompanyIndexes FSCI WITH (NOLOCK)
	 JOIN Reporting.dbo.DimDate D ON FSCI.Date_key = D.Date_key
	 JOIN Reporting.dbo.DimDate D0 ON FSCI.Date_key - 1 = D0.Date_key
	WHERE D.DayNum = 1
	 AND ((FSCI.IsBusiness = 1 AND FSCI.VacancyCount > 3) OR (FSCI.IsBusiness = 0 AND FSCI.VacancyCount > 1))
	 AND D0.YearNum BETWEEN @YearNum - 1 AND @YearNum
	GROUP BY D0.YearNum, D0.MonthNum, D0.MonthNameEng
	 )

	SELECT * 
	FROM C	
	WHERE Website = 'rabota.ua' AND RowNum BETWEEN 2 AND 13
	
	UNION ALL

	SELECT *
	FROM C
	WHERE Website = 'work.ua' AND RowNum BETWEEN 1 AND 12
	
	ORDER BY Website, YearNum, MonthNum;

	END
