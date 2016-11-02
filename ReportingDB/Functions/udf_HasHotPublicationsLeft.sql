
CREATE FUNCTION [dbo].[udf_HasHotPublicationsLeft] (@NotebookID INT)

RETURNS BIT

AS

BEGIN

DECLARE @Today DATETIME
DECLARE @CurDay SMALLINT

SET @Today = dbo.fnGetDatePart(GETDATE())
SET @CurDay = dbo.fnDayByDate(@Today)

	IF EXISTS (SELECT * 
			   FROM SRV16.RabotaUA2.dbo.NotebookCompany NC
			   WHERE NC.NotebookID = @NotebookID 
				AND NC.rtVacancyHot > 0
                AND EXISTS(SELECT * 
						   FROM SRV16.RabotaUA2.dbo.TicketPayment TP 
						   WHERE TP.NotebookId = NC.NotebookId 
							AND TP.TicketPaymentTypeID NOT IN (5,6) AND TP.State = 10 AND TP.VacancyHot > 0
							AND TP.ExpiryDate >= @Today)
              )

	RETURN 1;

RETURN 0;

END;
