
CREATE FUNCTION [dbo].[udf_HasPaidPublishedVacs_AtTime] (
 @NotebookId INT,
 @Date DATETIME
)
RETURNS BIT

AS

BEGIN

DECLARE @Day SMALLINT
SET @Day = dbo.fnDayByDate(@Date)

	IF EXISTS(SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompany_History
				WHERE NotebookID = @NotebookID AND Field IN ('rtVacancyStandart', 'rtVacancyDesigned', 'rtVacancyHot') 
					AND DateOfUpd BETWEEN @Date - 28 AND @Date)
			AND EXISTS(SELECT * FROM SRV16.RabotaUA2.dbo.TicketPayment WITH (NOLOCK) 
						WHERE NotebookID = @NotebookID AND State = 10 AND TicketPaymentTypeID NOT IN (5, 6)
							AND AddDate <= @Date AND ExpiryDate >= @Date - 28)
		RETURN 1

	IF EXISTS(SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompany_History WITH (NOLOCK)
				WHERE NotebookID = @NotebookID AND Field = 'rtVacancyRegional' AND DateOfUpd BETWEEN @Date - 28 AND @Date)
			AND EXISTS(SELECT * FROM SRV16.RabotaUA2.dbo.RegionalTicketPayment WITH (NOLOCK) 
						WHERE NotebookID = @NotebookID AND State = 10 AND TicketPaymentTypeID NOT IN (5, 6)
							AND AddDate <= @Date AND DateValid >= @Day - 28)
		RETURN 1

	RETURN 0

END