CREATE TABLE [dbo].[ResumeCountByPZ] (
    [ID]                 INT           IDENTITY (1, 1) NOT NULL,
    [FullDate]           DATE          NOT NULL,
    [PZ]                 NVARCHAR (50) NOT NULL,
    [Rabota_ResumeCount] INT           NOT NULL,
    [Work_ResumeCount]   INT           NOT NULL,
    CONSTRAINT [PK_ResumeCountByPZ] PRIMARY KEY CLUSTERED ([ID] ASC)
);

