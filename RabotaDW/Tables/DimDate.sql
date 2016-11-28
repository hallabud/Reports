CREATE TABLE [dbo].[DimDate]
(
	[DateKey] INT NOT NULL, 
    [FullDate] DATE NOT NULL, 
	[DayNumOfYear] SMALLINT NOT NULL,
	[DayNumOfMonth] TINYINT NOT NULL,     
	[DayNumOfWeek] TINYINT NOT NULL,     
    [DayNameOfWeekEng] NVARCHAR(15) NOT NULL,
    [DayNameOfWeekUkr] NVARCHAR(15) NOT NULL,
    [DayNameOfWeekRus] NVARCHAR(15) NOT NULL,
	[WeekNumOfYear] TINYINT NOT NULL, 
    [WeekNumOfMonth] TINYINT NOT NULL,
    [WeekFirstDate] DATE NOT NULL, 
    [WeekLastDate] DATE NOT NULL, 
    [WeekName] NVARCHAR(15) NOT NULL,  
    [MonthNum] TINYINT NOT NULL, 
    [MonthNameEng] NVARCHAR(15) NOT NULL,
    [MonthNameUkr] NVARCHAR(15) NOT NULL, 
	[MonthNameRus] NVARCHAR(15) NOT NULL, 
    [MonthIsLastDate] BIT NOT NULL, 		
    [MonthFirstDate] DATE NOT NULL, 
    [MonthLastDate] DATE NOT NULL, 
    [QuarterNum] TINYINT NOT NULL, 
	[QuarterName] NVARCHAR(15) NOT NULL,
    [QuarterFirstDate] DATE NOT NULL, 
    [QuarterLastDate] DATE NOT NULL,
	[YearNum] SMALLINT NOT NULL, 
    CONSTRAINT [PK_DimDate] PRIMARY KEY ([DateKey]) 
)

GO

CREATE UNIQUE INDEX [UNQ_DimDate_FullDate] ON [dbo].[DimDate] ([FullDate])
