CREATE TABLE [dbo].[DimRubrics] (
    [RubricID]   INT           IDENTITY (1, 1) NOT NULL,
    [RubricId1]  INT           NOT NULL,
    [RubricId2]  INT           NOT NULL,
    [Rubric1]    VARCHAR (255) NOT NULL,
    [Rubric2]    VARCHAR (255) NOT NULL,
    [RubricName] AS            (([Rubric1]+' - ')+[Rubric2]) PERSISTED NOT NULL,
    CONSTRAINT [PK_DimRubrics] PRIMARY KEY CLUSTERED ([RubricID] ASC)
);

