CREATE TABLE [dbo].[FactSpiderCompanyIndexes] (
    [SpiderCompanyID]  INT NOT NULL,
    [Date_key]         INT NOT NULL,
    [VacancyCount]     INT NOT NULL,
    [HotVacancyCount]  INT NOT NULL,
    [Paid]             BIT NOT NULL,
    [IsPaidByTickets]  BIT NOT NULL,
    [IsHasLogo]        BIT NULL,
    [IsBusiness]       BIT NULL,
    [IsHasLogo_OnMain] BIT NULL,
    CONSTRAINT [PK_FactSpiderCompanyIndexes] PRIMARY KEY CLUSTERED ([SpiderCompanyID] ASC, [Date_key] ASC),
    CONSTRAINT [FK_FactSpiderCompanyIndexes_SpiderCompanyID] FOREIGN KEY ([SpiderCompanyID]) REFERENCES [dbo].[DimSpiderCompany] ([SpiderCompanyID])
);


GO
CREATE NONCLUSTERED INDEX [IX_IsBusiness]
    ON [dbo].[FactSpiderCompanyIndexes]([IsBusiness] ASC)
    INCLUDE([SpiderCompanyID], [Date_key]);


GO
CREATE NONCLUSTERED INDEX [IX_FactSpiderCompanyIndexes_IsPaidByTickets_WithIncluded]
    ON [dbo].[FactSpiderCompanyIndexes]([IsPaidByTickets] ASC)
    INCLUDE([SpiderCompanyID], [Date_key], [VacancyCount], [IsBusiness]);


GO
CREATE NONCLUSTERED INDEX [IX_FactSpiderCompanyIndexes_HotVacancyCount_WithIncluded]
    ON [dbo].[FactSpiderCompanyIndexes]([HotVacancyCount] ASC)
    INCLUDE([SpiderCompanyID], [Date_key]);


GO
CREATE NONCLUSTERED INDEX [IX_FactSpiderCompanyIndexes_Date_key_HotVacancyCount_Included_SpiderCompanyID]
    ON [dbo].[FactSpiderCompanyIndexes]([Date_key] ASC, [HotVacancyCount] ASC)
    INCLUDE([SpiderCompanyID]);


GO
CREATE NONCLUSTERED INDEX [IX_FactSpiderCompanyIndexes_IsHasLogo_WithIncluded]
    ON [dbo].[FactSpiderCompanyIndexes]([IsHasLogo] ASC)
    INCLUDE([SpiderCompanyID], [Date_key]);


GO
CREATE NONCLUSTERED INDEX [IX_FactSpiderCompanyIndexes_IsHasLogoOnMain_WithIncluded]
    ON [dbo].[FactSpiderCompanyIndexes]([IsHasLogo_OnMain] ASC)
    INCLUDE([SpiderCompanyID], [Date_key]);


GO
CREATE NONCLUSTERED INDEX [IX_DateKey_WithIncluded]
    ON [dbo].[FactSpiderCompanyIndexes]([Date_key] ASC)
    INCLUDE([SpiderCompanyID], [VacancyCount], [HotVacancyCount], [Paid], [IsPaidByTickets], [IsHasLogo], [IsBusiness], [IsHasLogo_OnMain]);

