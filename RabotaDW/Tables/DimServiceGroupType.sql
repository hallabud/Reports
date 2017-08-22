CREATE TABLE [dbo].[DimServiceGroupType]
(
	[ServiceGroupTypeKey] SMALLINT NOT NULL, 
    [ServiceGroupType] NVARCHAR(50) NOT NULL, 
    CONSTRAINT [PK_DimServiceGroupType] PRIMARY KEY ([ServiceGroupTypeKey]) 
)
