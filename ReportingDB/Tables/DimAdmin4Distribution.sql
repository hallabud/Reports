CREATE TABLE [dbo].[DimAdmin4Distribution] (
    [DistributionID]   INT            NOT NULL,
    [LetterSubject]    NVARCHAR (200) NOT NULL,
    [StartDate]        DATETIME       NOT NULL,
    [EndDate]          DATETIME       NOT NULL,
    [FinishDate]       DATE           NOT NULL,
    [TotalSubscribers] INT            NOT NULL,
    [AddDate]          DATETIME       CONSTRAINT [DF_DimAdmin4Distribution_AddDate] DEFAULT (getdate()) NOT NULL,
    [DistributionName] NVARCHAR (100) NULL,
    CONSTRAINT [PK_DimAdmin4Distribution] PRIMARY KEY CLUSTERED ([DistributionID] ASC)
);

