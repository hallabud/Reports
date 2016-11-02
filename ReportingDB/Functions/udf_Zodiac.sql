﻿
CREATE FUNCTION dbo.udf_Zodiac
(
	@BirthDate DATETIME
)
RETURNS VARCHAR(20)

AS

BEGIN

	DECLARE @Zodiac VARCHAR(20)

	SET @Zodiac = CASE 
					WHEN RIGHT(CONVERT(VARCHAR, @BirthDate, 102),5) BETWEEN '01.21' AND '02.18' THEN 'Водолей'
					WHEN RIGHT(CONVERT(VARCHAR, @BirthDate, 102),5) BETWEEN '02.19' AND '03.20' THEN 'Рыбы'
					WHEN RIGHT(CONVERT(VARCHAR, @BirthDate, 102),5) BETWEEN '03.21' AND '04.20' THEN 'Овен'
					WHEN RIGHT(CONVERT(VARCHAR, @BirthDate, 102),5) BETWEEN '04.21' AND '05.21' THEN 'Телец'
					WHEN RIGHT(CONVERT(VARCHAR, @BirthDate, 102),5) BETWEEN '05.22' AND '06.21' THEN 'Близнецы'
					WHEN RIGHT(CONVERT(VARCHAR, @BirthDate, 102),5) BETWEEN '06.22' AND '07.22' THEN 'Рак'
					WHEN RIGHT(CONVERT(VARCHAR, @BirthDate, 102),5) BETWEEN '07.23' AND '08.23' THEN 'Лев'
					WHEN RIGHT(CONVERT(VARCHAR, @BirthDate, 102),5) BETWEEN '08.24' AND '09.23' THEN 'Дева'
					WHEN RIGHT(CONVERT(VARCHAR, @BirthDate, 102),5) BETWEEN '09.24' AND '10.23' THEN 'Весы'
					WHEN RIGHT(CONVERT(VARCHAR, @BirthDate, 102),5) BETWEEN '10.24' AND '11.22' THEN 'Скорпион'
					WHEN RIGHT(CONVERT(VARCHAR, @BirthDate, 102),5) BETWEEN '11.23' AND '12.21' THEN 'Стрелец'
					-- WHEN RIGHT(CONVERT(VARCHAR, @BirthDate, 102),5) BETWEEN '12.22' AND '01.20' THEN 'Козерог'
					ELSE 'Козерог'
				  END;

	RETURN @Zodiac

END
