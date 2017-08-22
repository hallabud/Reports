CREATE TABLE [dbo].[DimService]
(
	[OrderServiceID] SMALLINT NOT NULL, 
    [OrderServiceName] NVARCHAR(255) NOT NULL, 
    [ServiceGroupKey] SMALLINT NOT NULL, 
    CONSTRAINT [PK_DimService] PRIMARY KEY ([OrderServiceID]), 
    CONSTRAINT [FK_DimService_DimServiceGroup] FOREIGN KEY (ServiceGroupKey) REFERENCES [DimServiceGroup](ServiceGroupKey) 
)
