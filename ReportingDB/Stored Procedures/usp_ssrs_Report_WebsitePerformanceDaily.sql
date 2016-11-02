CREATE PROCEDURE [dbo].[usp_ssrs_Report_WebsitePerformanceDaily] @ReportDate DATETIME
 
AS 

BEGIN

IF OBJECT_ID('tempdb..#Dates','U') IS NOT NULL DROP TABLE #Dates;
IF OBJECT_ID('tempdb..#UspSpeed','U') IS NOT NULL DROP TABLE #UspSpeed;

CREATE TABLE #Dates (FullTime1 DATETIME, FullTime2 DATETIME);
CREATE TABLE #UspSpeed (FullDate DATETIME, ServerName NCHAR(1), Name NVARCHAR(30), Value DECIMAL(8,4));

DECLARE @DateTime DATETIME = @ReportDate;

WHILE @DateTime <> DATEADD(DAY, 1, @ReportDate)

	BEGIN

		INSERT INTO #Dates VALUES (@DateTime, DATEADD(MINUTE, 10, @DateTime))

		SET @DateTime = DATEADD(MINUTE, 10, @DateTime)

	END

INSERT INTO #UspSpeed
SELECT CAST(CONVERT(VARCHAR, ExecDate, 100) AS DATETIME) AS FullDate, NULL AS ServerName, PL.Name AS Name, Avg(DeltaMS) / 1000. AS Value
FROM SRV16.RabotaUA2.dbo.__ProcStatistic PS WITH (NOLOCK)
	JOIN SRV16.RabotaUA2.dbo.__ProcList PL WITH (NOLOCK) ON PS.ProcID = PL.ID
WHERE PS.ProcID IN (17, 402, 1021, 399)
	AND ExecDate BETWEEN @ReportDate AND @ReportDate + 1
GROUP BY CAST(CONVERT(VARCHAR, ExecDate, 100) AS DATETIME), PL.Name

IF @ReportDate = dbo.fnGetDatePart(GETDATE())

	BEGIN

	SELECT 
	   FullTime2 AS FullDate
	 , 'SRV16' AS ServerName
	 , 'Сервис перегружен, кол-во ошибок' AS Name
	 , (SELECT COUNT(ID) FROM SRV16.RabotaUA2.dbo.TempDB_LOG WITH (NOLOCK) WHERE Type IN (1,2,3,4) AND AddDate BETWEEN D.FullTime1 AND D.FullTime2) AS Value
	FROM #Dates D
	
	UNION ALL

	SELECT 
	   FullTime2 AS FullDate
	 , 'SRV14' AS ServerName
	 , 'Сервис перегружен, кол-во ошибок' AS Name
	 , (SELECT COUNT(ID) FROM SRV14.RabotaUA2.dbo.TempDB_LOG WITH (NOLOCK) WHERE Type IN (1,2,3,4) AND AddDate BETWEEN D.FullTime1 AND D.FullTime2) AS Value
	FROM #Dates D

	UNION ALL

	SELECT D.FullTime2, ServerName, Name, AVG(Value)
	FROM #UspSpeed US
	 JOIN #Dates D ON US.FullDate BETWEEN D.FullTime1 AND D.FullTime2
	GROUP BY D.FullTime2, ServerName, Name
	 
	ORDER BY FullTime2, Name

	END

IF  @ReportDate <> dbo.fnGetDatePart(GETDATE())

	BEGIN

	SELECT 
	   FullTime2 AS FullDate
	 , 'SRV16' AS ServerName
	 , 'Сервис перегружен, кол-во ошибок' AS Name
	 , (SELECT COUNT(ID) FROM SRV16.RabotaUA2.dbo.TempDB_LOG WITH (NOLOCK) WHERE Type IN (1,2,3,4) AND AddDate BETWEEN D.FullTime1 AND D.FullTime2) AS Value
	FROM #Dates D
	
	UNION ALL

	SELECT 
	   FullTime2 AS FullDate
	 , 'SRV14' AS ServerName
	 , 'Сервис перегружен, кол-во ошибок' AS Name
	 , (SELECT COUNT(ID) FROM SRV14.RabotaUA2.dbo.TempDB_LOG WITH (NOLOCK) WHERE Type IN (1,2,3,4) AND AddDate BETWEEN D.FullTime1 AND D.FullTime2) AS Value
	FROM #Dates D

	UNION ALL

	SELECT CAST(CONVERT(VARCHAR, MIN(ExecDate), 100) AS DATETIME) AS FullDate, NULL AS ServerName, PL.Name AS Name, Avg(PSA.AvgTime) / 1000. AS Value
	FROM SRV16.RabotaUA2.dbo.__ProcStatistic_Aggregator_Detail PSA WITH (NOLOCK)
	 JOIN SRV16.RabotaUA2.dbo.__ProcList PL WITH (NOLOCK) ON PSA.ProcID = PL.ID
	WHERE PSA.ProcID IN (17, 402, 1021, 399)
	 AND ExecDate BETWEEN @ReportDate AND @ReportDate + 1
	GROUP BY PL.Name,
		DATEPART(YEAR, ExecDate),
		DATEPART(MONTH, ExecDate),
		DATEPART(DAY, ExecDate),
		DATEPART(HOUR, ExecDate),
		(DATEPART(MINUTE, ExecDate) / 10)

	ORDER BY FullDate, Name

	END

DROP TABLE #Dates;
DROP TABLE #UspSpeed;

END;