CREATE TABLE [dbo].[DimNotebookState]
(
	[NotebookStateID] INT NOT NULL , 
    [NotebookStateName] NVARCHAR(255) NOT NULL, 
    CONSTRAINT [PK_DimNotebookState] PRIMARY KEY ([NotebookStateID])
)
