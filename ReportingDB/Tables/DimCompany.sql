CREATE TABLE [dbo].[DimCompany] (
    [Company_key]          INT             IDENTITY (1, 1) NOT NULL,
    [Region_key]           INT             NOT NULL,
    [NotebookId]           INT             NOT NULL,
    [CompanyName]          VARCHAR (255)   NOT NULL,
    [AddDate]              DATETIME        CONSTRAINT [DF__DimCompan__AddDa__619B8048] DEFAULT (getdate()) NOT NULL,
    [RegDate]              DATE            NOT NULL,
    [FirstPubDate]         DATE            NULL,
    [CompanyState]         VARCHAR (20)    NOT NULL,
    [ManagerName]          VARCHAR (100)   NOT NULL,
    [DepartmentName]       VARCHAR (40)    NOT NULL,
    [VacancyNum]           SMALLINT        NOT NULL,
    [AgeGroup]             VARCHAR (20)    NOT NULL,
    [IsAgency]             BIT             NOT NULL,
    [HasWebsite]           BIT             NOT NULL,
    [WorkConnectionGroup]  VARCHAR (50)    NOT NULL,
    [WorkCompanyID]        INT             NULL,
    [WorkCompanyName]      VARCHAR (255)   NULL,
    [WorkVacancyNum]       SMALLINT        NULL,
    [WorkFirstPubDate]     DATE            NULL,
    [VacancyNumMonth1]     INT             NULL,
    [VacancyNumMonth2]     INT             NULL,
    [VacancyNumMonth3]     INT             NULL,
    [WorkVacancyNumMonth1] INT             NULL,
    [WorkVacancyNumMonth2] INT             NULL,
    [WorkVacancyNumMonth3] INT             NULL,
    [AvgLast3Month]        DECIMAL (20, 4) NULL,
    [IndexActivity]        TINYINT         NULL,
    [IndexAttraction]      DECIMAL (6, 4)  NULL,
    [VacancyDiffGroup]     VARCHAR (20)    NULL,
    [ManagerEmail]         VARCHAR (150)   NULL,
    [StarRating]           AS              (case when [IndexAttraction]>=(7) AND [IndexAttraction]<=(10) then (5) when [IndexAttraction]>=(4.5) AND [IndexAttraction]<=(7) then (4) when [IndexAttraction]>=(3) AND [IndexAttraction]<=(4.5) then (3) when [IndexAttraction]>=(1) AND [IndexAttraction]<=(3) then (2) when [IndexAttraction]>(0) then (1) else (0) end) PERSISTED NOT NULL,
    [UnqVacancyNum]        SMALLINT        NULL,
    [UnqWorkVacancyNum]    SMALLINT        NULL,
    [ManagerStartDate]     DATE            CONSTRAINT [DF_DimCompany_ManagerStartDate] DEFAULT (CONVERT([date],getdate())) NULL,
    CONSTRAINT [PK_DimCompany] PRIMARY KEY CLUSTERED ([Company_key] ASC) WITH (FILLFACTOR = 70),
    CONSTRAINT [UNQ_NotebookId] UNIQUE NONCLUSTERED ([NotebookId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_CompanyState]
    ON [dbo].[DimCompany]([CompanyState] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_ForPortfolio]
    ON [dbo].[DimCompany]([ManagerName] ASC, [DepartmentName] ASC, [AgeGroup] ASC, [VacancyDiffGroup] ASC, [StarRating] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_WorkCompanyID_NotebookID]
    ON [dbo].[DimCompany]([WorkCompanyID] ASC)
    INCLUDE([NotebookId]);


GO
CREATE NONCLUSTERED INDEX [IX_WorkConnectionGroup]
    ON [dbo].[DimCompany]([WorkConnectionGroup] ASC, [ManagerEmail] ASC, [ManagerStartDate] ASC);


GO

-- ========================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-04-20
-- Description:	если меняется менеджер компании, то обновляем "дату начала работы менеджера с компанией"
--				ManagerStartDate
-- ========================================================================================================
-- ========================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Modify date: 2016-07-12
-- Description:	Меняется "логика". Если ManagerStartDate IS NULL и компании назначается менеджер с 
--				ManagerName	NOT IN ('Евгения Татарова','rabota.ua'), т.е. компании назначается 
--				"реальный", а не "костыльный" менеджер, то присваиваем полю ManagerStartDate текущую дату 
-- ========================================================================================================
-- ========================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Modify date: 2016-10-21
-- Description:	Снова меняется "логика". :)
--				Если компании назначается "реальный" менеджер (любой кроме rabota.ua или Евгения 
--				Татарова), а до этого был "костыльный", то присваиваем полю ManagerStartDate текущую дату
-- ========================================================================================================

CREATE TRIGGER [dbo].[tr_DimCompany_InsertUpdate]  ON [dbo].[DimCompany]
    FOR UPDATE
    
	AS
    
	BEGIN
    
	SET NOCOUNT ON

	IF UPDATE(ManagerName)
		UPDATE DC
		SET ManagerStartDate = CONVERT(DATE, GETDATE())
		FROM dbo.DimCompany DC
		 JOIN deleted D ON DC.Company_key = D.Company_key
		 JOIN inserted I ON DC.Company_key = D.Company_key
		WHERE I.ManagerName <> D.ManagerName
		 AND I.ManagerName NOT IN ('Евгения Татарова','rabota.ua')
		 AND D.ManagerName IN ('Евгения Татарова','rabota.ua')

    END
