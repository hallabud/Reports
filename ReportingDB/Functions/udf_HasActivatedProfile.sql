
CREATE FUNCTION [dbo].[udf_HasActivatedProfile] (@NotebookID INT)

RETURNS BIT

AS

BEGIN

DECLARE @Today DATETIME
DECLARE @CurDay SMALLINT

SET @Today = dbo.fnGetDatePart(GETDATE())
SET @CurDay = dbo.fnDayByDate(@Today)
	
	IF EXISTS (SELECT *
			   FROM SRV16.RabotaUA2.dbo.OrderDetail OD
				JOIN SRV16.RabotaUA2.dbo.Orders O ON OD.OrderID = O.ID
			   WHERE O.NotebookID = @NotebookID
				AND OD.ServiceID IN (25,26)
				AND @Today BETWEEN OD.ActivationStartDate AND OD.ActivationEndDate)
	RETURN 1;

RETURN 0;

END;
