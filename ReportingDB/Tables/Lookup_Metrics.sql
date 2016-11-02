CREATE TABLE [dbo].[Lookup_Metrics] (
    [MetricID]   INT           IDENTITY (1, 1) NOT NULL,
    [MetricName] VARCHAR (150) NOT NULL,
    CONSTRAINT [PK_Lookup_Metrics] PRIMARY KEY CLUSTERED ([MetricID] ASC)
);

