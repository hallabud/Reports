CREATE TABLE [dbo].[FactMetricsNewUsers_Traffic] (
    [YearNum]         INT       NOT NULL,
    [WeekNum]         INT       NOT NULL,
    [WeekName]        CHAR (13) NOT NULL,
    [MetricID]        INT       NOT NULL,
    [TrafficSourceID] INT       NOT NULL,
    [MetricValue]     INT       NOT NULL,
    CONSTRAINT [PK_FactMetricsNewUsers_Traffic] PRIMARY KEY CLUSTERED ([YearNum] ASC, [WeekNum] ASC, [WeekName] ASC, [MetricID] ASC, [TrafficSourceID] ASC),
    CONSTRAINT [FK_FactMetricsNewUsersTraffic_Lookup_Metrics] FOREIGN KEY ([MetricID]) REFERENCES [dbo].[Lookup_Metrics] ([MetricID])
);

