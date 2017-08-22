CREATE TABLE [dbo].[DimOrder]
(
	[OrderID] INT NOT NULL, 
    [NotebookID] INT NOT NULL, 
    [LoginEmail_OrderOwner] NVARCHAR(100) NOT NULL, 
    [CatalogPriceSum] MONEY NOT NULL, 
    [ClientPriceSum] MONEY NOT NULL, 
    [WaitActivationDate] SMALLDATETIME NOT NULL, 
    [AddDate] SMALLDATETIME NOT NULL, 
    [UpdateDate] SMALLDATETIME NOT NULL, 
    CONSTRAINT [PK_DimOrder] PRIMARY KEY ([OrderID]), 
    CONSTRAINT [FK_DimOrder_DimNotebookCompany] FOREIGN KEY (NotebookID) REFERENCES DimNotebookCompany(NotebookID) 
)
