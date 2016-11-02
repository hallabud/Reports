CREATE TABLE [dbo].[ReportEngagementValues] (
    [Date_key]    INT             NOT NULL,
    [Index_key]   SMALLINT        NOT NULL,
    [Index_Value] DECIMAL (13, 5) NOT NULL,
    CONSTRAINT [PK_ReportEngagementValues] PRIMARY KEY CLUSTERED ([Date_key] ASC, [Index_key] ASC),
    CONSTRAINT [FK_ReportEngagementValues_Date_key] FOREIGN KEY ([Date_key]) REFERENCES [dbo].[DimDate] ([Date_key]),
    CONSTRAINT [FK_ReportEngagementValues_Index_key] FOREIGN KEY ([Index_key]) REFERENCES [dbo].[ReportEngagementIndexes] ([Index_key])
);

