CREATE FUNCTION [dbo].[fnGetPeriodIntersection] (
	@DayFrom1 INT,
	@DayTo1 INT,
	@DayFrom2 INT,
	@DayTo2 INT
)
RETURNS FLOAT
/**************************************************************************************************
 CREATED BY	:	Andrew Smiyan
 CREATED ON	:	16.11.2012
 COMMENTS	:	Вычисление отношения длины пересечения интервалов 
				<@DayFrom1-@DayTo1> и <@DayFrom2-@DayTo2> к длине интервала <@DayFrom1-@DayTo1>.

				Если в вызывающей процедуре указаны параметры, определяющие "дату с" и "дату по",
				то их значения надо передавать в @DayFrom2 и @DayTo2.
***************************************************************************************************/
AS
BEGIN
	DECLARE @Result INT

	IF @DayFrom1 > @DayTo1 OR @DayFrom2 > @DayTo2
		RETURN 0
	ELSE IF @DayFrom2 <= @DayFrom1 AND @DayTo2 >= @DayTo1
		RETURN 1
	ELSE IF @DayTo2 < @DayFrom1 OR @DayTo1 < @DayFrom2
		RETURN 0
	ELSE IF @DayFrom1 BETWEEN @DayFrom2 AND @DayTo2 AND @DayTo1 >= @DayTo2
		SET @Result = @DayTo2 - @DayFrom1 + 1
	ELSE IF @DayFrom2 BETWEEN @DayFrom1 AND @DayTo1 AND @DayTo2 >= @DayTo1
		SET @Result = @DayTo1 - @DayFrom2 + 1
	ELSE
		SET @Result = @DayTo2 - @DayFrom2 + 1

	RETURN 1. * @Result / (@DayTo1 - @DayFrom1 + 1)
END
