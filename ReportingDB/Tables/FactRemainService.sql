CREATE TABLE [dbo].[FactRemainService] (
    [Date_key]      INT             NOT NULL,
    [Service_key]   INT             NOT NULL,
    [RemainService] DECIMAL (18, 2) NOT NULL,
    CONSTRAINT [PK_FactRemainService] PRIMARY KEY CLUSTERED ([Date_key] ASC, [Service_key] ASC),
    CONSTRAINT [FK_FactRemainService_Date_key] FOREIGN KEY ([Date_key]) REFERENCES [dbo].[DimDate] ([Date_key]),
    CONSTRAINT [FK_FactRemainService_Service_key] FOREIGN KEY ([Service_key]) REFERENCES [dbo].[DimService] ([Service_key])
);

