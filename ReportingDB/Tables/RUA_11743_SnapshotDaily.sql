CREATE TABLE [dbo].[RUA_11743_SnapshotDaily] (
    [ReportDate]       DATETIME NOT NULL,
    [VacancyBlocked]   INT      NOT NULL,
    [VacancyPublished] INT      NOT NULL,
    CONSTRAINT [PK_RUA_11743] PRIMARY KEY CLUSTERED ([ReportDate] ASC)
);

