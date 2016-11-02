CREATE FUNCTION [dbo].[fnDayByDate] (@Date datetime) RETURNS INT 
WITH SCHEMABINDING 
AS
BEGIN
	declare @Day INT
	declare @StartDate datetime
	set @StartDate='01/01/2006'
	set @Day= DATEDIFF(day, @StartDate, @Date) 

	RETURN @Day

END