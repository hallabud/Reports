
CREATE FUNCTION [dbo].[udf_HasPaidPublishedVacs] (@NotebookID INT)

RETURNS BIT

AS

BEGIN

DECLARE @Today DATETIME
DECLARE @CurDay SMALLINT

SET @Today = dbo.fnGetDatePart(GETDATE())
SET @CurDay = dbo.fnDayByDate(@Today)
 
	IF EXISTS(SELECT NotebookID FROM SRV16.RabotaUA2.dbo.VacancyPublished V WITH (NOLOCK) 
				WHERE NotebookID = @NotebookID AND IsFree = 0
					AND NOT (ISNULL(RegionalPackageID, '') = '18' 
								AND ISNULL((SELECT TOP 1 R.TicketPaymentTypeID FROM SRV16.RabotaUA2.dbo.RegionalTicketPayment R 
										JOIN SRV16.RabotaUA2.dbo.NotebookCompany_Spent S ON S.TicketPaymentID = R.ID
									WHERE S.VacancyID = V.ID ORDER BY S.ID DESC), 0) = 6))
			AND EXISTS(SELECT ID FROM SRV16.RabotaUA2.dbo.TicketPayment WITH (NOLOCK) 
						WHERE NotebookID = @NotebookID AND State = 10 AND TicketPaymentTypeID NOT IN (5, 6) AND ExpiryDate >= @Today
						UNION ALL 
						SELECT ID FROM SRV16.RabotaUA2.dbo.RegionalTicketPayment WITH (NOLOCK) 
						WHERE NotebookID = @NotebookID AND State = 10 AND TicketPaymentTypeID NOT IN (5, 6) AND DateValid >= @CurDay)
		RETURN 1;

	IF EXISTS(SELECT NotebookID FROM SRV16.RabotaUA2.dbo.VacancyPublished V WITH (NOLOCK) 
				WHERE NotebookID = @NotebookID AND IsFree = 0
					AND NOT (ISNULL(RegionalPackageID, '') = '18' 
								AND ISNULL((SELECT TOP 1 R.TicketPaymentTypeID FROM SRV16.RabotaUA2.dbo.RegionalTicketPayment R 
										JOIN SRV16.RabotaUA2.dbo.NotebookCompany_Spent S ON S.TicketPaymentID = R.ID
									WHERE S.VacancyID = V.ID ORDER BY S.ID DESC), 0) = 6))
			AND EXISTS(SELECT ID FROM SRV16.RabotaUA2.dbo.TicketPayment WITH (NOLOCK) 
						WHERE NotebookID = @NotebookID AND State = 10 AND TicketPaymentTypeID NOT IN (5, 6) AND ExpiryDate >= @Today - 28
						UNION ALL 
						SELECT ID FROM SRV16.RabotaUA2.dbo.RegionalTicketPayment WITH (NOLOCK) 
						WHERE NotebookID = @NotebookID AND State = 10 AND TicketPaymentTypeID NOT IN (5, 6) AND DateValid >= @CurDay - 28)
		RETURN 1

RETURN 0;

END;
