CREATE TABLE [dbo].[FactAdmin4DistributionStats] (
    [FullDate]       DATE     NOT NULL,
    [DistributionID] INT      NOT NULL,
    [Sent]           INT      NOT NULL,
    [Delivered]      INT      NOT NULL,
    [Opened]         INT      NOT NULL,
    [Clicked]        INT      NOT NULL,
    [AddDate]        DATETIME CONSTRAINT [DF_FactAdmin4DistributionStats_AddDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_FactAdmin4DistributionStats] PRIMARY KEY CLUSTERED ([FullDate] ASC, [DistributionID] ASC)
);

