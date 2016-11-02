CREATE FUNCTION [dbo].[udf_FullMonthsSeparation] 
(
    @DateA DATETIME,
    @DateB DATETIME
)
RETURNS INT
AS
BEGIN
    DECLARE @Result INT

    SET @Result = (
    				SELECT 
    				CASE 
    					WHEN DATEPART(DAY, @DateA) > DATEPART(DAY, @DateB)
    					THEN DATEDIFF(MONTH, @DateA, @DateB) - 1
    					ELSE DATEDIFF(MONTH, @DateA, @DateB)
    				END
    				)

    RETURN @Result
END
