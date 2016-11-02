CREATE FUNCTION [dbo].[fnGetMaximumOf2ValuesDate]
(@Param1 DATE, @Param2 DATE)

RETURNS DATE

AS

BEGIN

DECLARE @Result DATE;
SET @Result = CASE WHEN @Param1 > @Param2 THEN @Param1 ELSE @Param2 END;
RETURN @Result;

END