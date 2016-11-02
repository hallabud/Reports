
CREATE PROCEDURE [dbo].[usp_ssrs_Report_RecognizedRevenuesByCompaniesDetailed]
	@ManagerID INT 

AS

DECLARE @StartDate DATE = DATEADD(QUARTER, -4, DATEADD(QUARTER,DATEDIFF(QUARTER,0,GETDATE()),0));
DECLARE @TodayDateKey INT = (SELECT Date_key FROM dbo.DimDate WHERE FullDate = CONVERT(DATE, GETDATE()));

WITH Dates AS
 (
SELECT DISTINCT D0.YearNum, D0.QuarterNum, D0.MonthNum, D0.MonthNameRus, D1.Date_key AS FirstMonthDateKey, D2.Date_key AS LastMonthDateKey
FROM dbo.DimDate D0
 JOIN dbo.DimDate D1 ON D0.FirstMonthDate = D1.FullDate
 JOIN dbo.DimDate D2 ON D0.LastMonthDate = D2.FullDate
WHERE D0.FullDate BETWEEN @StartDate AND GETDATE()
 )
 , Notebooks AS
 (
SELECT NC.NotebookID
 , FCS.HasPaidPublicationsLeft
 , FCS.HasHotPublicationsLeft
 , FCS.HasCVDBAccess
 , FCS.HasActivatedLogo
 , FCS.HasActivatedProfile
 , NC.Name AS CompanyName
 , DC.VacancyNum + ISNULL(DC.UnqWorkVacancyNum,0) AS UnqVacancyNum
FROM Analytics.dbo.NotebookCompany NC 
 JOIN dbo.DimCompany DC ON NC.NotebookId = DC.NotebookId
 JOIN dbo.FactCompanyStatuses FCS ON FCS.Date_key = @TodayDateKey AND DC.Company_key = FCS.Company_key
WHERE ManagerID = @ManagerID
 )
 , NotebookDates AS
 (
SELECT * 
FROM Notebooks
 CROSS JOIN Dates
 )
 , ResultTable AS
 (
SELECT ND.YearNum
 , ND.QuarterNum
 , ND.MonthNum
 , ND.MonthNameRus
 , ND.NotebookID
 , ND.CompanyName
 , ND.HasPaidPublicationsLeft
 , ND.HasHotPublicationsLeft
 , ND.HasCVDBAccess
 , ND.HasActivatedLogo
 , ND.HasActivatedProfile
 , ND.UnqVacancyNum
 , ISNULL(RRN.Service_key,0) AS Service_key
 , DS.ServiceName
 , SUM(RRN.RecognizedRevenue) AS SumRR
 , SUM(SUM(RRN.RecognizedRevenue)) OVER(PARTITION BY ND.NotebookID) AS NotebookTotalRR
 , SUM(SUM(RRN.RecognizedRevenue)) OVER(PARTITION BY ND.NotebookID, ND.YearNum, ND.MonthNum) AS NotebookMonthTotalRR
 , SUM(SUM(RRN.RecognizedRevenue)) OVER(PARTITION BY ND.NotebookID, ND.YearNum, ND.QuarterNum) AS NotebookQuarterTotalRR
FROM NotebookDates ND
 LEFT JOIN dbo.FactRecognizedRevenueNotebook RRN ON ND.NotebookId = RRN.NotebookID AND RRN.Date_key BETWEEN ND.FirstMonthDateKey AND ND.LastMonthDateKey
 LEFT JOIN dbo.DimService DS ON RRN.Service_key = DS.Service_key
GROUP BY ND.YearNum
 , ND.QuarterNum
 , ND.MonthNum
 , ND.MonthNameRus
 , ND.NotebookID
 , ND.CompanyName
 , ND.HasPaidPublicationsLeft
 , ND.HasPaidPublicationsLeft
 , ND.HasHotPublicationsLeft
 , ND.HasCVDBAccess
 , ND.HasActivatedLogo
 , ND.HasActivatedProfile
 , ND.UnqVacancyNum
 , ISNULL(RRN.Service_key,0)
 , DS.ServiceName
 )
SELECT *
 , MAX(NotebookMonthTotalRR) OVER() AS MaxNotebookMonthlyRR
 , MAX(NotebookQuarterTotalRR) OVER() AS MaxNotebookQuarterRR
FROM ResultTable RT0
WHERE EXISTS (SELECT * FROM ResultTable RT1 WHERE RT0.NotebookId = RT1.NotebookId AND SumRR > 0)
ORDER BY NotebookID, YearNum, MonthNum, ServiceName;