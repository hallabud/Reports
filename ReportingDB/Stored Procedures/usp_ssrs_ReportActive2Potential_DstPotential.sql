CREATE PROCEDURE [dbo].[usp_ssrs_ReportActive2Potential_DstPotential] (@YearNum SMALLINT, @MonthNum TINYINT)

AS

-- Определение потенциала Активных 2 в выбранном году (@YearNum) и месяце (@MonthNum)

BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN TRANSACTION

IF OBJECT_ID('tempdb..#Notebooks','U') IS NOT NULL
 DROP TABLE #Notebooks;

CREATE TABLE #Notebooks (MonthNum TINYINT, NotebookID INT, CONSTRAINT PK_Notebooks PRIMARY KEY(MonthNum, NotebookID));

DECLARE @MonthFirstDate DATETIME; SELECT @MonthFirstDate = MIN(FullDate) FROM dbo.DimDate WHERE YearNum = @YearNum AND MonthNum = @MonthNum;
DECLARE @PrevMonthFirstDate DATETIME; SELECT @PrevMonthFirstDate = DATEADD(MONTH, -1, @MonthFirstDate);
DECLARE @BeforePrevMonthFirstDate DATETIME; SELECT @BeforePrevMonthFirstDate = DATEADD(MONTH, -2, @MonthFirstDate);

INSERT INTO #Notebooks
SELECT DISTINCT 
   DATEPART(MONTH, NCS.AddDate) AS MonthNum
 , NCS.NotebookId
FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent NCS
 JOIN SRV16.RabotaUA2.dbo.Notebook N ON NCS.NotebookID = N.Id
WHERE N.NotebookStateId = 7
 AND NCS.AddDate >= @BeforePrevMonthFirstDate AND NCS.AddDate < @MonthFirstDate;

WITH C AS
 (
SELECT NotebookID, COUNT(*) AS MonthNum
FROM #Notebooks N1
WHERE EXISTS (SELECT * FROM #Notebooks WHERE NotebookID = N1.NotebookId AND MonthNum = CASE WHEN @MonthNum = 1 THEN 12 ELSE @MonthNum - 1 END)
GROUP BY NotebookID
 )
SELECT 
   1 AS HasPublicationsPrevMonth
 , MonthNum - 1 IsActive2
 , COUNT(*) AS CompaniesNum
FROM C
GROUP BY MonthNum - 1;

DROP TABLE #Notebooks;

COMMIT TRANSACTION

END