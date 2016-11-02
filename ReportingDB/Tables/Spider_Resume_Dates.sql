CREATE TABLE [dbo].[Spider_Resume_Dates] (
    [SpiderResumeID]    INT      NOT NULL,
    [ResumeDate]        DATETIME NOT NULL,
    [IsFirstResumeDate] BIT      NOT NULL,
    CONSTRAINT [PK_Spider_Resume_Dates] PRIMARY KEY CLUSTERED ([SpiderResumeID] ASC, [ResumeDate] ASC),
    CONSTRAINT [FK_Spider_Resume_Dates_Spider_Resume] FOREIGN KEY ([SpiderResumeID]) REFERENCES [dbo].[Spider_Resume] ([SpiderResumeID])
);

