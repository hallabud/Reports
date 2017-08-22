CREATE TABLE [dbo].[FactRecognizedRevenue]
(
	[DateKey] INT NOT NULL, 
    [NotebookID] INT NOT NULL, 
	OrderID INT NOT NULL,
	[OrderServiceID] SMALLINT NOT NULL, 
    [RecognizedRevenueAmount] MONEY NOT NULL, 
	CONSTRAINT [PK_FactRecognizedRevenue] PRIMARY KEY ([DateKey], [OrderID], [NotebookID], [OrderServiceID]),
    CONSTRAINT [FK_FactRecognizedRevenue_DimNotebookCompany] FOREIGN KEY (NotebookID) REFERENCES DimNotebookCompany(NotebookID), 
    CONSTRAINT [FK_FactRecognizedRevenue_DimService] FOREIGN KEY (OrderServiceID) REFERENCES DimService(OrderServiceID), 
    CONSTRAINT [FK_FactRecognizedRevenue_DimOrder] FOREIGN KEY (OrderID) REFERENCES DimOrder(OrderID), 
    CONSTRAINT [FK_FactRecognizedRevenue_DimDate] FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey)
)
