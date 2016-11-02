
CREATE FUNCTION [dbo].[udf_GetNotebookCompanyList_WithoutFreeTickets]
(
    @Day INT
)
RETURNS TABLE AS RETURN
(
    SELECT DISTINCT NRT.NotebookID, 1 AS IsAllFreeTicketsSpent
	FROM SRV16.RabotaUA2.dbo.NotebookRegionalTicket NRT
	 JOIN SRV16.RabotaUA2.dbo.RegionalTicketPayment RTP ON NRT.PayId = RTP.Id
	WHERE NRT.PackageId = 18 AND RTP.TicketPaymentTypeID = 6
	 AND dbo.fnDayByDate(GETDATE()) BETWEEN NRT.DateStart AND NRT.DateValid
	 AND NRT.TicketRestCount <= 0
)