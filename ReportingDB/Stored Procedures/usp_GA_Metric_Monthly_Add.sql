
CREATE PROCEDURE [dbo].[usp_GA_Metric_Monthly_Add] 
	@MetricName NVARCHAR(100),
	@YearNum INT,
	@MonthNum TINYINT,
	@MetricValue DECIMAL(12,4)

AS 	

BEGIN


DECLARE @MetricID INT = (SELECT ID FROM dbo.GA_Lookup_Indexes WHERE IndexName = @MetricName);

INSERT INTO dbo.GA_Fact_Indexes_Monthly(YearNum, MonthNum, IndexID, Value, AddDate) VALUES (@YearNum, @MonthNum, @MetricID, @MetricValue, SYSDATETIME());

END;