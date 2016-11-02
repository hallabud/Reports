CREATE TABLE [dbo].[LinkedCompaniesVacancyCount] (
    [Date_key]   INT           NOT NULL,
    [Website]    NVARCHAR (50) NOT NULL,
    [PubType]    NVARCHAR (50) NOT NULL,
    [VacancyCnt] INT           NOT NULL,
    CONSTRAINT [PK_LinkedCompaniesVacancyCount] PRIMARY KEY CLUSTERED ([Date_key] ASC, [Website] ASC, [PubType] ASC)
);

