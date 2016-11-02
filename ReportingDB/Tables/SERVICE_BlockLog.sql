CREATE TABLE [dbo].[SERVICE_BlockLog] (
    [BlockLog_ID]  INT             IDENTITY (1, 1) NOT NULL,
    [DBName]       NVARCHAR (128)  NOT NULL,
    [WhoIsBlocked] SMALLINT        NOT NULL,
    [BlockedLogin] NVARCHAR (256)  NOT NULL,
    [BlockerID]    SMALLINT        NOT NULL,
    [BlockerLogin] NVARCHAR (256)  NOT NULL,
    [BlockerQuery] NVARCHAR (4000) NOT NULL,
    [AddDate]      SMALLDATETIME   DEFAULT (getdate()) NOT NULL,
    PRIMARY KEY CLUSTERED ([BlockLog_ID] ASC)
);

