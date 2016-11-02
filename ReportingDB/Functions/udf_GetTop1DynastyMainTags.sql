
CREATE FUNCTION [dbo].[udf_GetTop1DynastyMainTags]
(
    @SynonymousID INT	
)
RETURNS VARCHAR(1000)

AS

BEGIN

	DECLARE @Result VARCHAR(1000);

	WITH C AS
	 (
	SELECT SG.SynonymousID, SG.Name, 0 AS Level
	FROM Analytics.dbo.SynonymGroup SG
	WHERE SG.SynonymousID = @SynonymousID

	UNION ALL

	SELECT SG.SynonymousID, SG.Name, Level + 1
	FROM Analytics.dbo.SynonymGroup_Parents SGP
	 JOIN Analytics.dbo.SynonymGroup SG ON SGP.ParentID = SG.SynonymousID
	 JOIN C ON C.SynonymousID = SGP.ChildID
	 )
	SELECT @Result =  
    (SELECT DISTINCT TOP 1 C0.Name
	FROM C C0
	WHERE NOT EXISTS (SELECT * FROM C C1 WHERE C1.Level > C0.Level))
	;

    RETURN @Result;

END

