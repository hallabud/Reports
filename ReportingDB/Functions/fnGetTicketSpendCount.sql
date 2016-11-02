CREATE FUNCTION [dbo].[fnGetTicketSpendCount] (
	@TicketPaymentID INT,
	@Type TINYINT
)
RETURNS INT
/**************************************************************************************************
 CREATED BY	:	Andrew Smiyan
 CREATED ON	:	10.10.2012
 COMMENTS	:	Вычисление количества потраченных билетов, привязанных к оплате @TicketPaymentID.
				Параметр @Type: 1 - Standard; 2 - Prof; 3 - VIP; 5 - Hot.
***************************************************************************************************/
AS
BEGIN
	DECLARE @Result INT

	SELECT @Result = SUM(Quantity) 
	FROM (
			SELECT TicketAwayCount AS Quantity 
			FROM SRV16.RabotaUA2.dbo.TicketAway WITH (NOLOCK)
			WHERE TicketPaymentID = @TicketPaymentID AND TicketType = @Type
			UNION ALL
			SELECT SpendCount AS Quantity 
			FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent WITH (NOLOCK)
			WHERE TicketPaymentID = @TicketPaymentID AND SpendType = @Type
		) A

	RETURN ISNULL(@Result, 0)
END

