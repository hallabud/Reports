CREATE TABLE [dbo].[AggrVacancyApplyByRegion] (
    [YearNum]         INT              NOT NULL,
    [WeekNum]         INT              NOT NULL,
    [WeekName]        NCHAR (13)       NOT NULL,
    [Region]          VARCHAR (255)    NOT NULL,
    [VacancyCount]    INT              NOT NULL,
    [ApplyCount]      INT              NOT NULL,
    [ApplyPerVacancy] NUMERIC (23, 11) NOT NULL,
    CONSTRAINT [PK_AggrVacancyApplyByRegion] PRIMARY KEY CLUSTERED ([YearNum] ASC, [WeekNum] ASC, [WeekName] ASC, [Region] ASC)
);

