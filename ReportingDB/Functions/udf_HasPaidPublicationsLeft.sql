
CREATE FUNCTION [dbo].[udf_HasPaidPublicationsLeft] (@NotebookID INT)

RETURNS BIT

AS

BEGIN

DECLARE @Today DATETIME
DECLARE @CurDay SMALLINT

SET @Today = dbo.fnGetDatePart(GETDATE())
SET @CurDay = dbo.fnDayByDate(@Today)
 
	DECLARE @TP TABLE (ID INT, VacancyStandart INT, VacancyDesigned INT, VacancyVIP INT, VacancyHot INT)

	INSERT INTO @TP (ID, VacancyStandart, VacancyDesigned, VacancyVIP, VacancyHot)
	SELECT ID, VacancyStandart, VacancyDesigned, VacancyVIP, VacancyHot
	FROM SRV16.RabotaUA2.dbo.TicketPayment WITH (NOLOCK)
	WHERE NotebookID = @NotebookID AND @Today BETWEEN dbo.fnGetDatePart(AddDate) AND ExpiryDate
		AND TicketPaymentTypeID NOT IN (5, 6) AND State = 10

	IF EXISTS(SELECT * FROM @TP WHERE VacancyStandart > dbo.fnGetTicketSpendCount(ID, 1))
		RETURN 1

	IF EXISTS(SELECT * FROM @TP WHERE VacancyDesigned > dbo.fnGetTicketSpendCount(ID, 2))
		RETURN 1

	IF EXISTS(SELECT * FROM @TP WHERE VacancyVIP > dbo.fnGetTicketSpendCount(ID, 3))
		RETURN 1

	IF EXISTS(SELECT * FROM @TP WHERE VacancyHot > dbo.fnGetTicketSpendCount(ID, 5))
		RETURN 1

	DECLARE @RTP TABLE (ID INT, PackageID INT, TicketCount INT)

	INSERT INTO @RTP (ID, PackageID, TicketCount)
	SELECT ID, PackageID, TicketCount
	FROM SRV16.RabotaUA2.dbo.RegionalTicketPayment WITH (NOLOCK)
	WHERE NotebookID = @NotebookID AND @CurDay BETWEEN DatePayment AND DateValid
		AND TicketPaymentTypeID NOT IN (5, 6) AND State = 10

	IF EXISTS(SELECT * FROM @RTP WHERE TicketCount > dbo.fnGetRegionalTicketSpendCount(ID, PackageID))
	RETURN 1

RETURN 0;

END;
