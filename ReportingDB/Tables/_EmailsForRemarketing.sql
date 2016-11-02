CREATE TABLE [dbo].[_EmailsForRemarketing] (
    [ID]                       INT           IDENTITY (1, 1) NOT NULL,
    [Email]                    VARCHAR (100) NULL,
    [AddDate]                  DATETIME      NULL,
    [Admin4_LastClickLinkDate] DATETIME      NULL,
    [TopCity]                  VARCHAR (100) NULL,
    [Gender]                   CHAR (1)      NULL,
    [Age]                      INT           NULL,
    [TopTag]                   VARCHAR (200) NULL
);

