CREATE TABLE [dbo].[Lookup_ParentGroups] (
    [ParentGroupID]   SMALLINT     IDENTITY (1, 1) NOT NULL,
    [ParentGroupName] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Lookup_SynonymAnalyticalGroups] PRIMARY KEY CLUSTERED ([ParentGroupID] ASC)
);

