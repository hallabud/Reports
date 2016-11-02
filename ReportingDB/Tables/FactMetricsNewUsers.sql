CREATE TABLE [dbo].[FactMetricsNewUsers] (
    [YearNum]            INT       NOT NULL,
    [WeekNum]            INT       NOT NULL,
    [WeekName]           CHAR (13) NOT NULL,
    [MetricID]           INT       NOT NULL,
    [ConversionSourceID] INT       NOT NULL,
    [MetricValue]        INT       NOT NULL,
    CONSTRAINT [PK_FactMetricsNewUsers] PRIMARY KEY CLUSTERED ([YearNum] ASC, [WeekNum] ASC, [WeekName] ASC, [MetricID] ASC, [ConversionSourceID] ASC),
    CONSTRAINT [FK_FactMetricsNewUsers_Lookup_ConversionSource] FOREIGN KEY ([ConversionSourceID]) REFERENCES [dbo].[Lookup_ConversionSource] ([ConversionSourceID]),
    CONSTRAINT [FK_FactMetricsNewUsers_Lookup_Metrics] FOREIGN KEY ([MetricID]) REFERENCES [dbo].[Lookup_Metrics] ([MetricID])
);

