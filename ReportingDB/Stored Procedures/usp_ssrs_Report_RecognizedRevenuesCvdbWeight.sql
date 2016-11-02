
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-05-27
-- Description:	Процедура возвращает потребление в разрезе блокнотов, типов сервиса и месяцев 
--				только по тем компаниям, у которых в отчетном месяце было потребление по сервису CVDB
-- ======================================================================================================


CREATE PROCEDURE [dbo].[usp_ssrs_Report_RecognizedRevenuesCvdbWeight]
	(@StartDate DATE, @EndDate DATE)

AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

WITH NotebooksWithCvdbInMonth AS
 (
SELECT DISTINCT D.YearNum, D.MonthNum, RRN.NotebookID
FROM Reporting.dbo.FactRecognizedRevenueNotebook RRN
 JOIN Reporting.dbo.DimDate D ON RRN.Date_key = D.Date_key
 JOIN Reporting.dbo.DimService S ON RRN.Service_key = S.Service_key
WHERE D.FullDate BETWEEN @StartDate AND @EndDate
 AND S.ServiceName = 'CVDB'
 )
SELECT D.YearNum, D.MonthNum, D.MonthNameEng, RRN.Service_key, S.ServiceName, RRN.NotebookID, NC.Name AS CompanyName, SUM(RRN.RecognizedRevenue) AS SumRR
FROM NotebooksWithCvdbInMonth CVDB
 JOIN Reporting.dbo.FactRecognizedRevenueNotebook RRN ON CVDB.NotebookID = RRN.NotebookID
 JOIN Reporting.dbo.DimDate D ON RRN.Date_key = D.Date_key
 JOIN Reporting.dbo.DimService S ON RRN.Service_key = S.Service_key
 JOIN Analytics.dbo.NotebookCompany NC ON RRN.NotebookID = NC.NotebookId
WHERE D.FullDate BETWEEN @StartDate AND @EndDate
 AND CVDB.MonthNum = D.MonthNum AND CVDB.YearNum = D.YearNum
GROUP BY D.YearNum, D.MonthNum, D.MonthNameEng, RRN.Service_key, S.ServiceName, RRN.NotebookID, NC.Name
 ;