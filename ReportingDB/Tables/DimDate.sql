CREATE TABLE [dbo].[DimDate] (
    [Date_key]         INT          IDENTITY (1, 1) NOT NULL,
    [FullDate]         DATETIME     NOT NULL,
    [YearNum]          SMALLINT     NOT NULL,
    [MonthNum]         TINYINT      NOT NULL,
    [MonthNameRus]     VARCHAR (15) NOT NULL,
    [MonthNameEng]     VARCHAR (15) NOT NULL,
    [WeekNum]          TINYINT      NOT NULL,
    [WeekName]         VARCHAR (15) NOT NULL,
    [FirstWeekDate]    DATETIME     NOT NULL,
    [LastWeekDate]     DATETIME     NOT NULL,
    [WeekDayNum]       TINYINT      NOT NULL,
    [DayNum]           TINYINT      NOT NULL,
    [WeekDayNameRus]   VARCHAR (15) NOT NULL,
    [WeekDayNameEng]   VARCHAR (15) NOT NULL,
    [DaysFrom20060101] INT          NOT NULL,
    [IsLastDayOfMonth] BIT          NOT NULL,
    [QuarterNum]       TINYINT      NOT NULL,
    [LastMonthDate]    DATETIME     NOT NULL,
    [FirstMonthDate]   DATETIME     NOT NULL,
    [LastQuarterDate]  DATETIME     NOT NULL,
    [FirstQuarterDate] DATETIME     NOT NULL,
    [PrvMonthYearNum]  SMALLINT     NOT NULL,
    [PrvMonthNum]      TINYINT      NOT NULL,
    [PrvMonthNameRus]  VARCHAR (15) NOT NULL,
    [PrvMonthNameEng]  VARCHAR (15) NOT NULL,
    [WeekOfMonthNum]   TINYINT      NOT NULL,
    [IsHoliday]        BIT          NULL,
    CONSTRAINT [PK_Calendar] PRIMARY KEY CLUSTERED ([Date_key] ASC),
    CONSTRAINT [UNQ_CalendarDate] UNIQUE NONCLUSTERED ([FullDate] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_IsLastDayOfMonth]
    ON [dbo].[DimDate]([IsLastDayOfMonth] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_DimDate_FullDate_WithIncluded]
    ON [dbo].[DimDate]([FullDate] ASC)
    INCLUDE([YearNum], [MonthNum], [MonthNameRus], [WeekNum], [WeekName]);


GO
CREATE NONCLUSTERED INDEX [IX_DayNum_InclFullDate]
    ON [dbo].[DimDate]([DayNum] ASC)
    INCLUDE([FullDate]);

