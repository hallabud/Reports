CREATE TABLE [dbo].[TargetsQuarterOverall] (
    [YearNum]           INT             NOT NULL,
    [QuarterNum]        TINYINT         NOT NULL,
    [ManagerID]         INT             NOT NULL,
    [ManagerName]       NVARCHAR (50)   NOT NULL,
    [SalesPlan]         DECIMAL (10, 2) NOT NULL,
    [ClientsPlan]       INT             NOT NULL,
    [UniqueVacancyPlan] DECIMAL (3, 2)  NOT NULL,
    [CoveragePlan]      DECIMAL (3, 2)  NOT NULL,
    CONSTRAINT [PK_TargetQuarterOverall] PRIMARY KEY CLUSTERED ([YearNum] ASC, [QuarterNum] ASC, [ManagerID] ASC)
);

