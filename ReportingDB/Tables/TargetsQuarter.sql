CREATE TABLE [dbo].[TargetsQuarter] (
    [YearNum]    INT             NOT NULL,
    [QuarterNum] TINYINT         NOT NULL,
    [WeekNum]    TINYINT         NOT NULL,
    [ManagerID]  INT             NOT NULL,
    [Income]     DECIMAL (10, 2) NOT NULL,
    [Clients]    INT             NULL,
    [Loyalty]    DECIMAL (5, 4)  NULL,
    CONSTRAINT [PK_TargetsQuarter_1] PRIMARY KEY CLUSTERED ([YearNum] ASC, [QuarterNum] ASC, [WeekNum] ASC, [ManagerID] ASC)
);

