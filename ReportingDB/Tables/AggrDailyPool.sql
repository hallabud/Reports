CREATE TABLE [dbo].[AggrDailyPool] (
    [FullDate]           DATE NOT NULL,
    [SynonymousID]       INT  NOT NULL,
    [CityID]             INT  NOT NULL,
    [VacancyCount]       INT  NOT NULL,
    [VacancyCount_New]   INT  NOT NULL,
    [VacancyCount_Upd]   INT  NOT NULL,
    [VacancyViews_New]   INT  NOT NULL,
    [VacancyViews_Upd]   INT  NOT NULL,
    [ResponsesCount_New] INT  NOT NULL,
    [ResponsesCount_Upd] INT  NOT NULL,
    CONSTRAINT [PK_AggrDailyPool] PRIMARY KEY CLUSTERED ([FullDate] ASC, [SynonymousID] ASC, [CityID] ASC)
);

