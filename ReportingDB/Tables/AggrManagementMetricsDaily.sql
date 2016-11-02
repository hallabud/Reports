CREATE TABLE [dbo].[AggrManagementMetricsDaily] (
    [FullDate]        DATETIME NOT NULL,
    [Responses]       INT      NOT NULL,
    [ResponsesViewed] INT      NOT NULL,
    CONSTRAINT [PK_AggrManagementMetricsDaily] PRIMARY KEY CLUSTERED ([FullDate] ASC)
);

