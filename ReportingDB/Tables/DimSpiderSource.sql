CREATE TABLE [dbo].[DimSpiderSource] (
    [SpiderSource_key] TINYINT      NOT NULL,
    [SpiderSourceName] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_DimSpiderSource] PRIMARY KEY CLUSTERED ([SpiderSource_key] ASC)
);

