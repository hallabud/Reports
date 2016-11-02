


CREATE FUNCTION [dbo].[udf_NotebookId_SalesChannelRecommended_HasChanged_DatePeriod]
(
    @NotebookId INT,
	@StartDate DATETIME,
	@EndDate DATETIME	
)
RETURNS BIT
AS
BEGIN

	DECLARE @Result BIT;
	
	SET @Result =
	(SELECT DISTINCT 1 
	FROM SRV16.RabotaUA2.dbo.NotebookCompany_SalesChannel_Recommended_History SCR
	 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC ON SCR.NotebookId = NC.NotebookID 
	WHERE SCR.NotebookID = @NotebookId 
	 AND SCR.AddDate BETWEEN @StartDate AND @EndDate
	 AND SCR.SalesChannel = 2
	 AND NC.SalesChannel_Recommended = 2);
		
    RETURN ISNULL(@Result, 0)

END
