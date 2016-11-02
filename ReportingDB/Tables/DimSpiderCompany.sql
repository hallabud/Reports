CREATE TABLE [dbo].[DimSpiderCompany] (
    [SpiderCompanyID]  INT            NOT NULL,
    [SpiderSource_key] TINYINT        NOT NULL,
    [RegDate_key]      INT            NOT NULL,
    [NotebookId]       INT            NULL,
    [ConnectionGroup]  AS             (case when [NotebookID] IS NOT NULL then 'Привязанная компания' else 'Нет привязки к компании на rabota.ua' end) PERSISTED NOT NULL,
    [CompanyID]        INT            NOT NULL,
    [CompanyName]      VARCHAR (200)  NOT NULL,
    [CompanyWebsite]   VARCHAR (100)  NULL,
    [IsAgency]         BIT            NOT NULL,
    [IsApproved]       BIT            NOT NULL,
    [CityId]           INT            NULL,
    [AddDate]          DATETIME       NOT NULL,
    [UpdateDate]       DATETIME       NOT NULL,
    [Rating]           TINYINT        NULL,
    [VacancyNumMonth1] INT            NULL,
    [VacancyNumMonth2] INT            NULL,
    [VacancyNumMonth3] INT            NULL,
    [AvgLast3Month]    AS             ((([VacancyNumMonth1]+[VacancyNumMonth2])+[VacancyNumMonth3])/(3.)) PERSISTED,
    [IndexActivity]    DECIMAL (6, 4) NULL,
    [IndexAttraction]  DECIMAL (6, 4) NULL,
    [StarRating]       AS             (case when [IndexAttraction]>=(7) AND [IndexAttraction]<=(10) then (5) when [IndexAttraction]>=(4.5) AND [IndexAttraction]<=(7) then (4) when [IndexAttraction]>=(3) AND [IndexAttraction]<=(4.5) then (3) when [IndexAttraction]>=(1) AND [IndexAttraction]<=(3) then (2) when [IndexAttraction]>(0) then (1) else (0) end) PERSISTED NOT NULL,
    [LastIsPaidDate]   DATE           NULL,
    CONSTRAINT [PK_DimSpiderCompany] PRIMARY KEY CLUSTERED ([SpiderCompanyID] ASC),
    CONSTRAINT [FK_DimSpiderCompany_DimSpiderSource] FOREIGN KEY ([SpiderSource_key]) REFERENCES [dbo].[DimSpiderSource] ([SpiderSource_key])
);


GO
CREATE NONCLUSTERED INDEX [IX_SpiderSource_Key]
    ON [dbo].[DimSpiderCompany]([SpiderSource_key] ASC)
    INCLUDE([SpiderCompanyID]);

