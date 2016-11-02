CREATE TABLE [dbo].[DimRegion] (
    [Region_key]          INT               IDENTITY (1, 1) NOT NULL,
    [AnalyticsDbId]       INT               NOT NULL,
    [NameRus]             VARCHAR (255)     NOT NULL,
    [NameUkr]             VARCHAR (255)     NOT NULL,
    [NameEng]             VARCHAR (255)     NOT NULL,
    [NameLocative]        VARCHAR (255)     NOT NULL,
    [RegionGroup]         VARCHAR (255)     NOT NULL,
    [RegionGroupPriority] TINYINT           NOT NULL,
    [GeoLocation]         [sys].[geography] NULL,
    [OblastCityID]        INT               NULL,
    CONSTRAINT [PK_DimRegion] PRIMARY KEY CLUSTERED ([Region_key] ASC),
    CONSTRAINT [UNQ_AnalyticsDbId] UNIQUE NONCLUSTERED ([AnalyticsDbId] ASC)
);

