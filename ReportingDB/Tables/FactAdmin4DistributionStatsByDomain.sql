CREATE TABLE [dbo].[FactAdmin4DistributionStatsByDomain] (
    [FullDate]       DATE           NOT NULL,
    [DistributionID] INT            NOT NULL,
    [Domain]         NVARCHAR (50)  NOT NULL,
    [DeliveryRate]   DECIMAL (7, 5) NOT NULL,
    [EmailsSent]     INT            NOT NULL,
    [AddDate]        DATETIME       CONSTRAINT [DF_FactAdmin4DistributionStatsByDomain_AddDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_FactAdmin4DistributionStatsByDomain] PRIMARY KEY CLUSTERED ([FullDate] ASC, [DistributionID] ASC, [Domain] ASC)
);

