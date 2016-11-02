CREATE PROCEDURE [dbo].[usp_ssrs_ReportActive2Potential_DstNew] (@YearNum SMALLINT, @MonthNum TINYINT)
AS

BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN TRANSACTION

DECLARE @MonthFirstDate DATETIME; SELECT @MonthFirstDate = MIN(FullDate) FROM dbo.DimDate WHERE YearNum = @YearNum AND MonthNum = @MonthNum;
DECLARE @PrevMonthFirstDate DATETIME; SELECT @PrevMonthFirstDate = DATEADD(MONTH, -1, @MonthFirstDate);
DECLARE @BeforePrevMonthFirstDate DATETIME; SELECT @BeforePrevMonthFirstDate = DATEADD(MONTH, -2, @MonthFirstDate);
DECLARE @NextMonthFirstDate DATETIME; SET @NextMonthFirstDate = DATEADD(MONTH, 1, @MonthFirstDate);

IF OBJECT_ID('tempdb..#Potential_New','U') IS NOT NULL DROP TABLE #Potential_New;
IF OBJECT_ID('tempdb..#Weeks_New','U') IS NOT NULL DROP TABLE #Weeks_New;
IF OBJECT_ID('tempdb..#Realization_New','U') IS NOT NULL DROP TABLE #Realization_New;

CREATE TABLE #Potential_New (MonthNum TINYINT, NotebookID INT, CONSTRAINT PK_Potential_New PRIMARY KEY(MonthNum, NotebookID));
CREATE TABLE #Weeks_New (WeekNum SMALLINT, FirstWeekDate DATETIME, LastWeekDate DATETIME, MonthWeekNum TINYINT, CONSTRAINT PK_Weeks_New PRIMARY KEY (MonthWeekNum));
CREATE TABLE #Realization_New (NotebookID INT, MonthWeekNum TINYINT, CONSTRAINT PK_Realization_New PRIMARY KEY(NotebookID));

INSERT INTO #Weeks_New
SELECT WeekNum, MIN(FullDate) AS FirstWeekDate, MAX(FullDate) + 1 AS LastWeekDate
 , ROW_NUMBER() OVER (ORDER BY WeekNum) AS MonthWeekNum
FROM dbo.DimDate DD
WHERE DD.MonthNum = @MonthNum
 AND DD.YearNum = @YearNum
GROUP BY WeekNum;

INSERT INTO #Potential_New
SELECT DISTINCT 
   DATEPART(MONTH, NCS.AddDate) AS MonthNum
 , NCS.NotebookId
FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent NCS
 JOIN SRV16.RabotaUA2.dbo.Notebook N ON NCS.NotebookID = N.Id
WHERE N.NotebookStateId = 7
 AND NCS.AddDate >= @BeforePrevMonthFirstDate AND NCS.AddDate < @MonthFirstDate;

WITH C AS
 (
SELECT NCS.NotebookID, MIN(NCS.AddDate) AS MinAddDate
FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent NCS
 JOIN SRV16.RabotaUA2.dbo.Notebook N ON NCS.NotebookID = N.Id
WHERE N.NotebookStateId = 7
 AND NCS.AddDate BETWEEN @MonthFirstDate AND @NextMonthFirstDate
GROUP BY NCS.NotebookID
 )
INSERT INTO #Realization_New
SELECT C.NotebookID, W.MonthWeekNum
FROM C
 JOIN #Weeks_New W ON C.MinAddDate BETWEEN W.FirstWeekDate AND W.LastWeekDate
 LEFT JOIN #Potential_New P ON C.NotebookID = P.NotebookID
WHERE P.NotebookId IS NULL;

SELECT 
   'Опубликовали в текущем месяце' AS CompaniesSegment
 , 'Неделя ' + CAST(MonthWeekNum AS VARCHAR) AS WeekNumber
 , COUNT(*) AS CompaniesNum
FROM #Realization_New
GROUP BY MonthWeekNum

DROP TABLE #Potential_New;
DROP TABLE #Weeks_New;
DROP TABLE #Realization_New;

COMMIT TRANSACTION

END