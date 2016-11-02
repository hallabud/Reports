
CREATE FUNCTION [dbo].[fnDateByDay] (@Day smallint) RETURNS datetime 
WITH SCHEMABINDING 
AS
BEGIN
	declare @Date datetime
	declare @StartDate datetime
	set @StartDate='01/01/2006'
	set @Date= DATEADD(day, @Day, @StartDate)
	RETURN @Date

END

