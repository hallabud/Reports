CREATE TABLE [dbo].[DimRabotaCompany]
(
	[CompanyKey] INT IDENTITY(1,1) NOT NULL PRIMARY KEY, 
    [CompanyId] INT NOT NULL, 
    [CompanyName] NVARCHAR(255) NULL, 
    [RegDate] DATETIME NULL, 
    [FirstPubDate] DATETIME NULL, 
    [CompanyStateId] TINYINT NULL,
	[CompanyState] NVARCHAR(50) NULL,  
    [ManagerKey] INT NULL, 
    [RegionId] SMALLINT NULL, 
    [IsMerged] BIT NULL, 
    [IsNonResident] BIT NULL, 
    [WorkCompanyID] INT NULL, 
    [MetaNotebookID] INT NULL, 
    [StartDate] DATETIME NULL, 
    [EndDate] DATETIME NULL
)
GO

ALTER TABLE [dbo].[DimRabotaCompany] ADD  CONSTRAINT [DF_DimRabotaCompany_IsMerged]  DEFAULT ((0)) FOR [IsMerged]