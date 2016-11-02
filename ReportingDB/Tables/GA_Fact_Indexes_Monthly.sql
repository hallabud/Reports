CREATE TABLE [dbo].[GA_Fact_Indexes_Monthly] (
    [YearNum]  INT           NOT NULL,
    [MonthNum] TINYINT       NOT NULL,
    [IndexID]  INT           NOT NULL,
    [Value]    INT           NOT NULL,
    [AddDate]  DATETIME2 (7) CONSTRAINT [DF_GA_Fact_Indexes_Monthly_AddDate] DEFAULT (sysdatetime()) NOT NULL,
    CONSTRAINT [PK_GA_Fact_Indexes_Monthly] PRIMARY KEY CLUSTERED ([YearNum] ASC, [MonthNum] ASC, [IndexID] ASC),
    CONSTRAINT [FK_GA_Fact_Indexes_Monthly_GA_Lookup_Indexes] FOREIGN KEY ([IndexID]) REFERENCES [dbo].[GA_Lookup_Indexes] ([ID])
);

