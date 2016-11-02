
CREATE PROCEDURE [dbo].[usp_etl_FactRecognizedRevenueNotebook]

AS

DECLARE @ReportDate DATETIME;
DECLARE @DateKey INT;

SET @ReportDate = DATEADD(DAY, -1, dbo.fnGetDatePart(GETDATE()))

CREATE TABLE #MonthResult (ID INT, NotebookID INT, SName VARCHAR(50), SSum DECIMAL(18,2));

SELECT @DateKey = Date_key FROM Reporting.dbo.DimDate WHERE Fulldate = @ReportDate;

INSERT INTO #MonthResult
EXEC dbo.usp_srv12_Report_Finance_UsedService_NotebookID @ReportDate, @ReportDate;

INSERT INTO Reporting.dbo.FactRecognizedRevenueNotebook (Date_key, Service_key, NotebookID, RecognizedRevenue)
SELECT @DateKey, ID, NotebookID, SSum
FROM #MonthResult;

DROP TABLE #MonthResult;