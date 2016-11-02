CREATE FUNCTION [dbo].[fnGetPZNamesBySynonymousID] (
	@SynonymousID INT
)
RETURNS NVARCHAR(4000)
AS
BEGIN
	DECLARE @PZName NVARCHAR(4000)

	SET @PZName = N''

	SELECT @PZName = @PZName + s.Name + ', '
	FROM SRV16.RabotaUA2.dbo.Synonymous s
	WHERE s.SynonymousID = @SynonymousID

	IF @PZName > ''
		SET @PZName = LEFT(@PZName, LEN(rtrim(@PZName)) - 1)

	RETURN @PZName
END