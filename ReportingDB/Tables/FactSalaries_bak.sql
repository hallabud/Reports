CREATE TABLE [dbo].[FactSalaries_bak] (
    [FullDate]       DATE            NOT NULL,
    [SalarySource]   TINYINT         NOT NULL,
    [RubricId1]      INT             NOT NULL,
    [RubricId2]      INT             NOT NULL,
    [CityId]         INT             NOT NULL,
    [ProfLevelId]    INT             NOT NULL,
    [ItemsCount]     INT             NOT NULL,
    [AvgSalary]      DECIMAL (18, 2) NOT NULL,
    [Median]         DECIMAL (18, 2) NOT NULL,
    [QuartileBottom] DECIMAL (18, 2) NOT NULL,
    [QuartileTop]    DECIMAL (18, 2) NOT NULL
);

