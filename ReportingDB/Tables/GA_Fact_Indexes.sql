CREATE TABLE [dbo].[GA_Fact_Indexes] (
    [IndexID] INT             NOT NULL,
    [AddDate] DATETIME2 (7)   CONSTRAINT [DF__GA_Fact_I__AddDa__37E53D9E] DEFAULT (sysdatetime()) NOT NULL,
    [Value]   DECIMAL (12, 4) NULL,
    CONSTRAINT [PK_IndexValue] PRIMARY KEY CLUSTERED ([IndexID] ASC, [AddDate] ASC),
    CONSTRAINT [FK_Lookup_Indexes] FOREIGN KEY ([IndexID]) REFERENCES [dbo].[GA_Lookup_Indexes] ([ID])
);

