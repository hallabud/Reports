CREATE PROCEDURE [dbo].[uspDimDatePopulate]
	@StartDate DATE,
	@EndDate DATE

AS

BEGIN

	SET DATEFIRST 1;
	SET LANGUAGE 'English';
	SET NOCOUNT ON;

	DECLARE @Date DATE = @StartDate;

	WHILE @Date <= @EndDate

		BEGIN

			INSERT INTO dbo.DimDate
			SELECT 
			   CONVERT(INT, REPLACE(CONVERT(VARCHAR, @Date), '-', '')) AS DateKey
			 , @Date AS FullDate
			 , DATEPART(DAYOFYEAR, @Date) AS DayNumOfYear
			 , DATEPART(DAY, @Date) AS DayNumOfMonth
			 , DATEPART(WEEKDAY, @Date) AS DayNumOfWeek
			 , DATENAME(WEEKDAY, @Date)  AS DayNameOfWeekEng
			 , CASE DATEPART(WEEKDAY, @Date) 
				WHEN 1 THEN 'Понеділок' WHEN 2 THEN 'Вівторок' WHEN 3 THEN 'Середа'	WHEN 4 THEN 'Четвер' WHEN 5 THEN 'П''ятниця' WHEN 6 THEN 'Субота' WHEN 7 THEN 'Неділя' END AS DayNameOfWeekUkr
			 , CASE DATEPART(WEEKDAY, @Date) 
				WHEN 1 THEN 'Понедельник' WHEN 2 THEN 'Вторник' WHEN 3 THEN 'Среда'	WHEN 4 THEN 'Четверг' WHEN 5 THEN 'Пятница'	WHEN 6 THEN 'Суббота' WHEN 7 THEN 'Воскресенье' END AS DayNameOfWeekRus
			 , DATEPART(WEEK, @Date) AS WeekNumOfYear
			 , DATEDIFF(WEEK, DATEADD(WEEK, DATEDIFF(WEEK, 0, DATEADD(MONTH, DATEDIFF(MONTH, 0, @Date), 0)), 0), DATEADD(DAY, -1, @Date)) + 1 AS WeekNumOfMonth
			 , CASE 
				WHEN DATEDIFF(YEAR, DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Date), @Date), @Date) > 0 
					THEN DATEADD(DAY, 1 - DATEPART(DAYOFYEAR, @Date), @Date)
				ELSE DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Date), @Date) 
			   END AS WeekFirstDate
			 , CASE
				WHEN DATEDIFF(YEAR, @Date, DATEADD(DAY, 7 - DATEPART(WEEKDAY, @Date), @Date)) > 0
					THEN DATEADD(YEAR, 1, DATEADD(DAY, - DATEPART(DAYOFYEAR, @Date), @Date)) 
				ELSE DATEADD(DAY, 7 - DATEPART(WEEKDAY, @Date), @Date) 
			   END AS WeekLastDate
			 , CASE 
				WHEN DATEDIFF(YEAR, DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Date), @Date), DATEADD(DAY, 7 - DATEPART(WEEKDAY, @Date), @Date)) = 0 
					THEN SUBSTRING(CONVERT(VARCHAR, DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Date), @Date), 104),1,5) + ' - ' + SUBSTRING(CONVERT(VARCHAR, DATEADD(DAY, 7 - DATEPART(WEEKDAY, @Date), @Date), 104),1,5) 
				WHEN DATEDIFF(YEAR, DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Date), @Date), @Date) > 0 
					THEN N'01.01' + ' - ' + SUBSTRING(CONVERT(VARCHAR, DATEADD(DAY, 7 - DATEPART(WEEKDAY, @Date), @Date), 104),1,5) 
				WHEN DATEDIFF(YEAR, @Date, DATEADD(DAY, 7 - DATEPART(WEEKDAY, @Date), @Date)) > 0 
					THEN SUBSTRING(CONVERT(VARCHAR, DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Date), @Date), 104),1,5) + ' - ' + N'31.12'
			   END AS WeekName
			 , DATEPART(MONTH, @Date) AS MonthNum
			 , DATENAME(MONTH, @Date) AS MonthNameEng
			 , CASE DATEPART(MONTH, @Date)
				WHEN 1 THEN 'Січень' WHEN 2 THEN 'Лютий' WHEN 3 THEN 'Березень' WHEN 4 THEN 'Квітень' WHEN 5 THEN 'Травень' WHEN 6 THEN 'Червень'
				WHEN 7 THEN 'Липень' WHEN 8 THEN 'Серпень' WHEN 9 THEN 'Вересень' WHEN 10 THEN 'Жовтень' WHEN 11 THEN 'Листопад' WHEN 12 THEN 'Грудень'
			   END AS MonthNameUkr
			 , CASE DATEPART(MONTH, @Date)
				WHEN 1 THEN 'Январь' WHEN 2 THEN 'Февраль' WHEN 3 THEN 'Март' WHEN 4 THEN 'Апрель' WHEN 5 THEN 'Май' WHEN 6 THEN 'Июнь'
				WHEN 7 THEN 'Июль' WHEN 8 THEN 'Август' WHEN 9 THEN 'Сентябрь' WHEN 10 THEN 'Октябрь' WHEN 11 THEN 'Ноябрь' WHEN 12 THEN 'Декабрь'
			   END AS MonthNameRus
			 , CASE WHEN @Date = DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1 - DATEPART(DAY, @Date), @Date))) THEN 1 ELSE 0 END AS MonthIsLastDate
			 , DATEADD(DAY, 1 - DATEPART(DAY, @Date), @Date) AS MonthFirstDate
			 , DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1 - DATEPART(DAY, @Date), @Date))) AS MonthLastDate
			 , DATEPART(QUARTER, @Date) AS QuarterNum
			 , 'Q' + CONVERT(VARCHAR, DATEPART(QUARTER, @Date)) AS QuarterName
			 , CONVERT(DATE, DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @Date), 0)) AS QuarterFirstDate
			 , CONVERT(DATE, DATEADD(DAY, -1, DATEADD(QUARTER, DATEDIFF(QUARTER, 0, @Date) + 1, 0))) AS QuarterLastDate
			 , YEAR(@Date) AS YearNum
			 , CASE WHEN DATEPART(WEEKDAY, @Date) IN (6,7) THEN 0 ELSE 1 END AS IsWorkingDay;

			 SET @Date = DATEADD(DAY, 1, @Date);

		END

END