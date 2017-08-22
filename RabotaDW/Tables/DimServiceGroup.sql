CREATE TABLE [dbo].[DimServiceGroup]
(
	[ServiceGroupKey] SMALLINT NOT NULL , 
    [ServiceGroup] NVARCHAR(50) NOT NULL, 
    [ServiceGroupTypeKey] SMALLINT NOT NULL, 
    CONSTRAINT [PK_DimServiceGroup] PRIMARY KEY ([ServiceGroupKey]), 
    CONSTRAINT [FK_DimServiceGroup_DimServiceGroupType] FOREIGN KEY (ServiceGroupTypeKey) REFERENCES DimServiceGroupType(ServiceGroupTypeKey)
)
