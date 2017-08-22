CREATE TABLE [dbo].[FactRecognizedRevenue]
(
	[DateKey] INT NOT NULL, 
    [NotebookID] INT NOT NULL, 
	[OrderServiceID] SMALLINT NOT NULL, 
    [RecognizedRevenueAmount] MONEY NOT NULL, 
    CONSTRAINT [FK_FactRecognizedRevenue_DimNotebookCompany] FOREIGN KEY (NotebookID) REFERENCES DimNotebookCompany(NotebookID), 
    CONSTRAINT [FK_FactRecognizedRevenue_DimService] FOREIGN KEY (OrderServiceID) REFERENCES DimService(OrderServiceID) 
)
