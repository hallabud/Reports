CREATE FUNCTION [dbo].[fnGetTicketSpendCountAtTime] (
	@TicketPaymentID INT,
	@Type TINYINT,
	@ReportDate DATETIME
)
RETURNS INT
/**************************************************************************************************
 CREATED BY	:	Mikhail Abdulakh
 CREATED ON	:	12.08.2013
 COMMENTS	:	Вычисление количества потраченных билетов на дату @ReportDate,
				привязанных к оплате @TicketPaymentID.
				Параметр @Type: 1 - Standard; 2 - Prof; 3 - VIP; 5 - Hot.
***************************************************************************************************/
AS
BEGIN
	DECLARE @Result INT

	SELECT @Result = SUM(Quantity) 
	FROM (
			SELECT TicketAwayCount AS Quantity 
			FROM SRV16.RabotaUA2.dbo.TicketAway 
			WHERE TicketPaymentID = @TicketPaymentID AND TicketType = @Type AND AddDate <= @ReportDate
			UNION ALL
			SELECT SpendCount AS Quantity
			FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent
			WHERE TicketPaymentID = @TicketPaymentID AND SpendType = @Type AND AddDate <= @ReportDate
		) A

	RETURN ISNULL(@Result, 0)
END
