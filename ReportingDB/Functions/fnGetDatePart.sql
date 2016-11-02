
CREATE FUNCTION [dbo].[fnGetDatePart] (
	@Date DATETIME
)
RETURNS DATETIME
/**************************************************************************************************
 MODIFIED BY:	Andrew Smiyan
 MODIFIED ON:	05.11.2009
 COMMENTS	:	Вместо типа REAL используем FLOAT.
***************************************************************************************************
 CREATED BY :	Andrew Smiyan
 CREATED ON :	18.03.2009
 COMMENTS	:	Возврат даты из переменной "дата-время".
***************************************************************************************************/
AS
BEGIN
	RETURN CONVERT(DATETIME, ROUND(CONVERT(FLOAT, @Date), 0, -1))
END
