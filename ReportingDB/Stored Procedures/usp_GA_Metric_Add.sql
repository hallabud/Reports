
CREATE PROCEDURE [dbo].[usp_GA_Metric_Add] 
	@MetricName NVARCHAR(100),
	@Date DATETIME2 = NULL,
	@MetricValue DECIMAL(12,4)

AS 	

BEGIN

IF @Date IS NULL SET @Date = SYSDATETIME();

DECLARE @MetricID INT = (SELECT ID FROM dbo.GA_Lookup_Indexes WHERE IndexName = @MetricName);

INSERT INTO dbo.GA_Fact_Indexes (IndexID, AddDate, Value) VALUES (@MetricID, @Date, @MetricValue)

END;