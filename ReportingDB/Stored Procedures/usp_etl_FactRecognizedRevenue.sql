
CREATE PROCEDURE [dbo].[usp_etl_FactRecognizedRevenue]

AS

DECLARE @ReportDate DATETIME;
DECLARE @DateKey INT;

SET @ReportDate = DATEADD(DAY, -1, dbo.fnGetDatePart(GETDATE()))

CREATE TABLE #MonthResult (ID INT, SName VARCHAR(50), SSum DECIMAL(18,2));

SELECT @DateKey = Date_key FROM Reporting.dbo.DimDate WHERE Fulldate = @ReportDate;

INSERT INTO #MonthResult
EXEC dbo.usp_srv12_Report_Finance_UsedService @ReportDate, @ReportDate;

INSERT INTO Reporting.dbo.FactRecognizedRevenue (Date_key, Service_key, RecognizedRevenue)
SELECT @DateKey, ID, SSum
FROM #MonthResult;

DROP TABLE #MonthResult;