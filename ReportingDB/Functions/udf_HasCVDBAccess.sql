
CREATE FUNCTION [dbo].[udf_HasCVDBAccess] (@NotebookID INT)

RETURNS BIT

AS

BEGIN

DECLARE @Today DATETIME
DECLARE @CurDay SMALLINT

SET @Today = dbo.fnGetDatePart(GETDATE())
SET @CurDay = dbo.fnDayByDate(@Today)

	IF EXISTS(SELECT * FROM SRV16.RabotaUA2.dbo.TemporalPayment
				WHERE NotebookID = @NotebookID AND @Today BETWEEN StartDate AND EndDate AND Price > 0)
		RETURN 1;

RETURN 0;

END;

