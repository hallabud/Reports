
CREATE FUNCTION [dbo].[udf_HasHotPublishedVacs] (@NotebookID INT)

RETURNS BIT

AS

BEGIN

DECLARE @Today DATETIME
DECLARE @CurDay SMALLINT

SET @Today = dbo.fnGetDatePart(GETDATE())
SET @CurDay = dbo.fnDayByDate(@Today)

	IF EXISTS(SELECT V.NotebookID FROM SRV16.RabotaUA2.dbo.VacancyPublished V WITH (NOLOCK) 
					JOIN SRV16.RabotaUA2.dbo.VacancyExtra VE ON VE.VacancyID = V.ID
				WHERE V.NotebookID = @NotebookID AND V.IsFree = 0
					AND @Today BETWEEN VE.HotStartDate AND VE.HotEndDate
					AND ISNULL((SELECT TOP 1 R.TicketPaymentTypeID FROM SRV16.RabotaUA2.dbo.TicketPayment R 
										JOIN SRV16.RabotaUA2.dbo.NotebookCompany_Spent S ON S.TicketPaymentID = R.ID
									WHERE S.VacancyID = V.ID AND S.SpendType = 5 
									ORDER BY S.ID DESC), 0) NOT IN (5, 6))
 
 RETURN 1;

RETURN 0;

END;
