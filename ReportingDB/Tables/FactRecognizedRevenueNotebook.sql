CREATE TABLE [dbo].[FactRecognizedRevenueNotebook] (
    [Date_key]          INT             NOT NULL,
    [Service_key]       INT             NOT NULL,
    [NotebookID]        INT             NOT NULL,
    [RecognizedRevenue] DECIMAL (18, 2) NOT NULL,
    CONSTRAINT [PK_FactRecognizedRevenueNotebook] PRIMARY KEY CLUSTERED ([Date_key] ASC, [Service_key] ASC, [NotebookID] ASC),
    CONSTRAINT [FK_FactRecognizedRevenueNotebook_DateKey] FOREIGN KEY ([Date_key]) REFERENCES [dbo].[DimDate] ([Date_key]),
    CONSTRAINT [FK_FactRecognizedRevenueNotebook_ServiceKey] FOREIGN KEY ([Service_key]) REFERENCES [dbo].[DimService] ([Service_key])
);


GO
CREATE NONCLUSTERED INDEX [IX_FactRecognizedRevenueNotebook]
    ON [dbo].[FactRecognizedRevenueNotebook]([NotebookID] ASC)
    INCLUDE([Date_key], [RecognizedRevenue]);

