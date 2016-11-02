CREATE TABLE [dbo].[FactRecognizedRevenue] (
    [Date_key]          INT             NOT NULL,
    [Service_key]       INT             NOT NULL,
    [RecognizedRevenue] DECIMAL (18, 2) NOT NULL,
    CONSTRAINT [PK_FactRecognizedRevenue] PRIMARY KEY CLUSTERED ([Date_key] ASC, [Service_key] ASC),
    CONSTRAINT [FK_FactRecognizedRevenue_DateKey] FOREIGN KEY ([Date_key]) REFERENCES [dbo].[DimDate] ([Date_key]),
    CONSTRAINT [FK_FactRecognizedRevenue_ServiceKey] FOREIGN KEY ([Service_key]) REFERENCES [dbo].[DimService] ([Service_key])
);

