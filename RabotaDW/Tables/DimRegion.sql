CREATE TABLE [dbo].[DimRegion]
(
	[Id] SMALLINT NOT NULL PRIMARY KEY, 
    [OblastCityID] SMALLINT NOT NULL, 
    [NameUkr] NVARCHAR(255) NULL, 
    [NameRus] NVARCHAR(255) NULL, 
    [NameEng] NVARCHAR(255) NULL, 
    [NameLocativeUkr] NVARCHAR(255) NULL, 
    [NameLocativeRus] NVARCHAR(255) NULL, 
    [IsRegionalCenter] BIT NOT NULL 
)
