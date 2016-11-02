CREATE TABLE [dbo].[ManagementMetrics] (
    [DateKey]    INT             NOT NULL,
    [IndexName]  VARCHAR (50)    NOT NULL,
    [IndexValue] DECIMAL (14, 4) NOT NULL,
    CONSTRAINT [PK_ManagementMetrics] PRIMARY KEY CLUSTERED ([DateKey] ASC, [IndexName] ASC)
);

