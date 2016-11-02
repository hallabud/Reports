CREATE TABLE [dbo].[ReportEngagementIndexes] (
    [Index_key]  SMALLINT      IDENTITY (1, 1) NOT NULL,
    [IndexGroup] VARCHAR (20)  NOT NULL,
    [IndexName]  VARCHAR (150) NOT NULL,
    CONSTRAINT [PK_ReportEngagementIndexes] PRIMARY KEY CLUSTERED ([Index_key] ASC)
);

