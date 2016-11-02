CREATE TABLE [dbo].[FactSalaries] (
    [Date_key]     INT             NOT NULL,
    [RubricID]     INT             NOT NULL,
    [CityId]       INT             NOT NULL,
    [ProfLevelId]  TINYINT         NOT NULL,
    [SalarySource] TINYINT         NOT NULL,
    [ItemID]       INT             NOT NULL,
    [Salary]       DECIMAL (18, 2) NOT NULL,
    CONSTRAINT [PK_FactSalaries] PRIMARY KEY CLUSTERED ([Date_key] ASC, [RubricID] ASC, [CityId] ASC, [ProfLevelId] ASC, [SalarySource] ASC, [ItemID] ASC),
    CONSTRAINT [FK_FactSalaries_DimCity] FOREIGN KEY ([CityId]) REFERENCES [dbo].[DimCity] ([Id]),
    CONSTRAINT [FK_FactSalaries_DimDate] FOREIGN KEY ([Date_key]) REFERENCES [dbo].[DimDate] ([Date_key]),
    CONSTRAINT [FK_FactSalaries_DimProfLevel] FOREIGN KEY ([ProfLevelId]) REFERENCES [dbo].[DimProfLevel] ([Id]),
    CONSTRAINT [FK_FactSalaries_DimRubrics] FOREIGN KEY ([RubricID]) REFERENCES [dbo].[DimRubrics] ([RubricID]),
    CONSTRAINT [FK_FactSalaries_DimSalarySource] FOREIGN KEY ([SalarySource]) REFERENCES [dbo].[DimSalarySource] ([Id])
);


GO
CREATE NONCLUSTERED INDEX [NCIX_Salary]
    ON [dbo].[FactSalaries]([Salary] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'1 - резюме; 2 - вакансии', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'FactSalaries', @level2type = N'COLUMN', @level2name = N'SalarySource';

