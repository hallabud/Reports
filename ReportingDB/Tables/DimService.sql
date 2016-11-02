CREATE TABLE [dbo].[DimService] (
    [Service_key]  INT          IDENTITY (1, 1) NOT NULL,
    [ServiceName]  VARCHAR (50) NOT NULL,
    [ServiceGroup] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Service] PRIMARY KEY CLUSTERED ([Service_key] ASC),
    CONSTRAINT [UNQ_ServiceName] UNIQUE NONCLUSTERED ([ServiceName] ASC)
);

