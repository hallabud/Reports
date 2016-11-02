CREATE TABLE [dbo].[FactResponsers] (
    [YearNum]       SMALLINT NOT NULL,
    [MonthNum]      TINYINT  NOT NULL,
    [ResponsersNum] INT      NOT NULL,
    CONSTRAINT [PK_FactResponses] PRIMARY KEY CLUSTERED ([YearNum] ASC, [MonthNum] ASC)
);

