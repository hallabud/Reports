CREATE TABLE [dbo].[Spider_Resume] (
    [SpiderResumeID] INT          NOT NULL,
    [ResumeLink]     VARCHAR (50) NOT NULL,
    [AddDate]        DATETIME     NOT NULL,
    CONSTRAINT [PK_Spider_Resume] PRIMARY KEY CLUSTERED ([SpiderResumeID] ASC)
);

