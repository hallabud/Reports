CREATE TABLE [dbo].[Lookup_ParentGroup_SynonymGroup] (
    [SynonymousID]  INT      NOT NULL,
    [ParentGroupID] SMALLINT NOT NULL,
    CONSTRAINT [PK_Lookup_ParentGroup_SynonymGroup] PRIMARY KEY CLUSTERED ([SynonymousID] ASC, [ParentGroupID] ASC)
);

