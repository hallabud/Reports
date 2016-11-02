CREATE TABLE [dbo].[SERVICE_IndexRebuildLog] (
    [IndexRebuildLog_ID] INT            IDENTITY (1, 1) NOT NULL,
    [IndexName]          NVARCHAR (128) NOT NULL,
    [TableName]          NVARCHAR (128) NOT NULL,
    [StartDate]          SMALLDATETIME  DEFAULT (getdate()) NOT NULL,
    [StopDate]           SMALLDATETIME  NULL,
    PRIMARY KEY CLUSTERED ([IndexRebuildLog_ID] ASC)
);

