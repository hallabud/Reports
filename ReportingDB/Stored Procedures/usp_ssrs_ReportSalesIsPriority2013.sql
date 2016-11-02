
CREATE PROCEDURE [dbo].[usp_ssrs_ReportSalesIsPriority2013]
AS

IF OBJECT_ID('tempdb..#LastDatesOfTheMonth','U') IS NOT NULL
 DROP TABLE #LastDatesOfTheMonth;

DECLARE @TodayDate DATETIME; SET @TodayDate = dbo.fnGetDatePart(GETDATE());

SELECT 
 MAX(FullDate) AS LastDateOfMonth
INTO #LastDatesOfTheMonth
FROM Reporting.dbo.DimDate
 WHERE FullDate BETWEEN '2012-01-01' AND @TodayDate
GROUP BY
   YearNum
 , MonthNum;

SELECT 
   NCE.NotebookId
 , NC.Name AS CompanyName
 , LD.LastDateOfMonth
 , CONVERT(VARCHAR(10),LD.LastDateOfMonth,104) AS LastDateOfMonthChar
 , dbo.fnIsPaidServicesExistsAtTime(NCE.NotebookId, LD.LastDateOfMonth) AS 'IsPaid'
FROM SRV16.RabotaUA2.dbo.NotebookCompanyExtra NCE
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC ON NCE.NotebookId = NC.NotebookId
 JOIN SRV16.RabotaUA2.dbo.Notebook N ON NC.NotebookId = N.Id
 CROSS JOIN #LastDatesOfTheMonth LD
WHERE Admin3_TrophyBrand_IsPriority2013 = 1
 AND N.NotebookStateId IN (5,7) 
 AND NC.Rating IN (4,5)
 AND NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompanyMerged WHERE SourceNotebookId = NC.NotebookId)


DROP TABLE #LastDatesOfTheMonth;