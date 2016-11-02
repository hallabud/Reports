CREATE FUNCTION [dbo].[fnGetMaximumOf2Values]
(@Param1 DECIMAL(20,4), @Param2 DECIMAL(20,4))

RETURNS DECIMAL(20,4)

AS

BEGIN

DECLARE @Result DECIMAL(20,4);
SET @Result = CASE WHEN @Param1 > @Param2 THEN @Param1 ELSE @Param2 END;
RETURN @Result;

END