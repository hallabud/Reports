CREATE TABLE [dbo].[FactCompletedActions]
(
	[DateKey] INT NOT NULL , 
    [CrmActionID] INT NOT NULL , 
    [ManagerKey] INT NULL, 
    [CompanyKey] INT NULL, 
    [ActionTypeId] INT NULL, 
    [ActionComment] NVARCHAR(4000) NULL, 
    [CompleteDate] DATETIME NULL, 
    [AddDate] DATETIME NULL, 
    [MetaNotebookID] INT NULL, 
    PRIMARY KEY ([DateKey], [CrmActionID])
)
