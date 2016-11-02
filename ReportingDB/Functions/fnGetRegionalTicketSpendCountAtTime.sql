CREATE FUNCTION [dbo].[fnGetRegionalTicketSpendCountAtTime] (
	@RegionalTicketPaymentID INT,
	@RegionalPackageID TINYINT,
	@ReportDate DATETIME
)
RETURNS INT
/**************************************************************************************************
 CREATED BY	:	Mikhail Abdulakh
 CREATED ON	:	12.08.2013
 COMMENTS	:	Вычисление количества потраченных региональных билетов, 
				привязанных к оплате @RegionalTicketPaymentID, на дату @ReportDate.
***************************************************************************************************/
AS
BEGIN
	DECLARE @Result INT

	SELECT @Result = SUM(Quantity) 
	FROM (
			SELECT TicketAwayCount AS Quantity 
			FROM SRV16.RabotaUA2.dbo.TicketAway 
			WHERE TicketPaymentID = @RegionalTicketPaymentID AND RegionalPackageID = @RegionalPackageID 
				AND AddDate <= @ReportDate
			UNION ALL
			SELECT SpendCount AS Quantity
			FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent
			WHERE TicketPaymentID = @RegionalTicketPaymentID AND RegionalPackageID = @RegionalPackageID 
				AND AddDate <= @ReportDate
		) A

	RETURN ISNULL(@Result, 0)
END
