
CREATE FUNCTION [dbo].[udf_HasPaidPublicationsLeft_AtTime] (@NotebookID INT, @Date DATETIME)

RETURNS BIT

AS

BEGIN

DECLARE @TicketCount INT

SELECT @TicketCount = SUM(NewValue)
FROM (
	SELECT NewValue, ROW_NUMBER() OVER (PARTITION BY Field ORDER BY DateOfUpd DESC) AS Number
	FROM SRV16.RabotaUA2.dbo.NotebookCompany_History WITH (NOLOCK)
	WHERE NotebookID = @NotebookID AND DateOfUpd <= @Date 
		AND Field IN ('rtVacancyStandart', 'rtVacancyDesigned')
	) A
WHERE Number = 1

IF @TicketCount > 0 
		AND EXISTS(SELECT * FROM SRV16.RabotaUA2.dbo.TicketPayment WITH (NOLOCK) 
					WHERE NotebookID = @NotebookID AND State = 10 AND TicketPaymentTypeID NOT IN (5, 6)
						AND @Date BETWEEN AddDate AND ExpiryDate)
	RETURN 1

DECLARE @Day SMALLINT
SET @Day = dbo.fnDayByDate(@Date)

SELECT @TicketCount = NewValue
FROM (
	SELECT NewValue, ROW_NUMBER() OVER (PARTITION BY Field ORDER BY DateOfUpd DESC) AS Number
	FROM SRV16.RabotaUA2.dbo.NotebookCompany_History WITH (NOLOCK)
	WHERE NotebookID = @NotebookID AND DateOfUpd <= @Date AND Field = 'rtVacancyRegional'
	) A
WHERE Number = 1

IF @TicketCount > 0 
		AND EXISTS(SELECT * FROM SRV16.RabotaUA2.dbo.RegionalTicketPayment WITH (NOLOCK) 
					WHERE NotebookID = @NotebookID AND State = 10 AND TicketPaymentTypeID NOT IN (5, 6)
						AND DateValid >= @Day AND AddDate <= @Date)
	RETURN 1

RETURN 0;

END;

