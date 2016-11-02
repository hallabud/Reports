CREATE PROCEDURE [dbo].[usp_ssrs_ReportActive2Potential_DstRealization] (@YearNum SMALLINT, @MonthNum TINYINT)
AS

BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN TRANSACTION

DECLARE @MonthFirstDate DATETIME; SELECT @MonthFirstDate = MIN(FullDate) FROM dbo.DimDate WHERE YearNum = @YearNum AND MonthNum = @MonthNum;
DECLARE @PrevMonthFirstDate DATETIME; SELECT @PrevMonthFirstDate = DATEADD(MONTH, -1, @MonthFirstDate);
DECLARE @BeforePrevMonthFirstDate DATETIME; SELECT @BeforePrevMonthFirstDate = DATEADD(MONTH, -2, @MonthFirstDate);
DECLARE @NextMonthFirstDate DATETIME; SET @NextMonthFirstDate = DATEADD(MONTH, 1, @MonthFirstDate);

IF OBJECT_ID('tempdb..#Potential','U') IS NOT NULL DROP TABLE #Potential;
IF OBJECT_ID('tempdb..#Weeks','U') IS NOT NULL DROP TABLE #Weeks;
IF OBJECT_ID('tempdb..#Potential_Final','U') IS NOT NULL DROP TABLE #Potential_Final;
IF OBJECT_ID('tempdb..#Realization','U') IS NOT NULL DROP TABLE #Realization;

CREATE TABLE #Potential (MonthNum TINYINT, NotebookID INT, CONSTRAINT PK_Potential PRIMARY KEY(MonthNum, NotebookID));
CREATE TABLE #Weeks (WeekNum SMALLINT, FirstWeekDate DATETIME, LastWeekDate DATETIME, MonthWeekNum TINYINT, CONSTRAINT PK_Weeks PRIMARY KEY (MonthWeekNum));
CREATE TABLE #Potential_Final (HasPublicationsPrevMonth BIT, IsActive2 BIT, NotebookID INT ,CONSTRAINT PK_Potential_Final PRIMARY KEY(NotebookID));
CREATE TABLE #Realization (NotebookID INT, MonthWeekNum TINYINT, IsActive2 BIT, CONSTRAINT PK_Realization PRIMARY KEY(NotebookID));

INSERT INTO #Weeks
SELECT WeekNum, MIN(FullDate) AS FirstWeekDate, MAX(FullDate) + 1 AS LastWeekDate
 , ROW_NUMBER() OVER (ORDER BY WeekNum) AS MonthWeekNum
FROM dbo.DimDate DD
WHERE DD.MonthNum = @MonthNum
 AND DD.YearNum = @YearNum
GROUP BY WeekNum;

INSERT INTO #Potential
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
FROM #Potential P1
WHERE EXISTS (SELECT * FROM #Potential WHERE NotebookID = P1.NotebookId AND MonthNum = CASE WHEN @MonthNum = 1 THEN 12 ELSE @MonthNum - 1 END)
GROUP BY NotebookID
 )
INSERT INTO #Potential_Final
SELECT 
   1 AS HasPublicationsPrevMonth
 , MonthNum - 1 AS IsActive2
 , NotebookId
FROM C;

WITH C AS
 (
SELECT NCS.NotebookID, MIN(NCS.AddDate) AS MinAddDate
FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent NCS
 JOIN SRV16.RabotaUA2.dbo.Notebook N ON NCS.NotebookID = N.Id
WHERE N.NotebookStateId = 7
 AND NCS.AddDate BETWEEN @MonthFirstDate AND @NextMonthFirstDate
GROUP BY NCS.NotebookID
 )
INSERT INTO #Realization
SELECT C.NotebookID, W.MonthWeekNum, PF.IsActive2
FROM C
 JOIN #Weeks W ON C.MinAddDate BETWEEN W.FirstWeekDate AND W.LastWeekDate
 JOIN #Potential_Final PF ON C.NotebookID = PF.NotebookID;

SELECT 
   'Неделя ' + CAST(MonthWeekNum AS VARCHAR) AS WeekNumber
 , IsActive2
 , COUNT(*) AS CompaniesNum
FROM #Realization
GROUP BY MonthWeekNum, IsActive2
UNION ALL
SELECT 
   'Реализованный потенциал'
 , IsActive2
 , COUNT(*)
FROM #Realization
GROUP BY IsActive2
UNION ALL
SELECT 
   'Нереализованный потенциал'
 , PF.IsActive2
 , COUNT(*)
FROM #Potential_Final PF
 LEFT JOIN #Realization R ON PF.NotebookID = R.NotebookID
WHERE R.NotebookID IS NULL
GROUP BY PF.IsActive2;

DROP TABLE #Potential;
DROP TABLE #Weeks;
DROP TABLE #Potential_Final;
DROP TABLE #Realization;

COMMIT TRANSACTION

END