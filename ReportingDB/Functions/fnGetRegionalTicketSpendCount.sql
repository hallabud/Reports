CREATE FUNCTION [dbo].[fnGetRegionalTicketSpendCount] (
	@TicketPaymentID INT,
	@PackageID TINYINT
)
RETURNS INT
/**************************************************************************************************
 CREATED BY	:	Mikhail Abdulakh
 CREATED ON	:	12.08.2013
 COMMENTS	:	Вычисление количества потраченных региональных билетов, 
				привязанных к оплате @TicketPaymentID.
***************************************************************************************************/
AS
BEGIN
	DECLARE @Result INT

	SELECT @Result = SUM(Quantity) 
	FROM (
			SELECT TicketAwayCount AS Quantity 
			FROM SRV16.RabotaUA2.dbo.TicketAway WITH (NOLOCK)
			WHERE TicketPaymentID = @TicketPaymentID AND RegionalPackageID = @PackageID 
			UNION ALL
			SELECT SpendCount AS Quantity
			FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent WITH (NOLOCK)
			WHERE TicketPaymentID = @TicketPaymentID AND RegionalPackageID = @PackageID 
		) A

	RETURN ISNULL(@Result, 0)
END
