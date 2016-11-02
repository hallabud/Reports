CREATE TABLE [dbo].[Lookup_ConversionSource] (
    [ConversionSourceID]   INT           IDENTITY (1, 1) NOT NULL,
    [ConversionSourceName] VARCHAR (150) NOT NULL,
    CONSTRAINT [PK_Lookup_ConversionSource] PRIMARY KEY CLUSTERED ([ConversionSourceID] ASC)
);

