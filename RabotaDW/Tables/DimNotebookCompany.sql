CREATE TABLE [dbo].[DimNotebookCompany]
(
	[NotebookID] INT NOT NULL , 
    [CompanyName] NVARCHAR(255) NOT NULL, 
    [NotebookStateID] INT NOT NULL, 
    CONSTRAINT [PK_DimNotebookCompany] PRIMARY KEY ([NotebookID]), 
    CONSTRAINT [FK_DimNotebookCompany_DimNotebookState] FOREIGN KEY (NotebookStateID) REFERENCES DimNotebookState (NotebookStateID)
)
