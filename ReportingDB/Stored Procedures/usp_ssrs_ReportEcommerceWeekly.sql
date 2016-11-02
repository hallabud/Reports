
CREATE PROCEDURE [dbo].[usp_ssrs_ReportEcommerceWeekly]
 (@StartDate DATETIME, @EndDate DATETIME)

AS

IF OBJECT_ID('tempdb..#FirstPayment_Dates','U') IS NOT NULL
 DROP TABLE #FirstPayment_Dates;

IF OBJECT_ID('tempdb..#Orders','U') IS NOT NULL
 DROP TABLE #Orders;

SELECT NotebookId, MIN(dbo.fnGetDatePart(AddDate)) AS FirstPaymentDate
INTO #FirstPayment_Dates
FROM
(
SELECT Tmp.NotebookId, Tmp.AddDate
FROM SRV16.RabotaUA2.dbo.TemporalPayment TmP
WHERE Tmp.NotebookPaymentStateID = 1 
UNION 
SELECT TP.NotebookId, TP.AddDate
FROM SRV16.RabotaUA2.dbo.TicketPayment TP
WHERE TP.NotebookPaymentStateId = 1 AND TP.State = 10 AND TP.TicketPaymentTypeID < 5
UNION
SELECT RTP.NotebookId, RTP.AddDate
FROM SRV16.RabotaUA2.dbo.RegionalTicketPayment RTP
WHERE RTP.NotebookPaymentStateId = 1 AND RTP.State = 10 AND RTP.TicketPaymentTypeID < 5
) AS Payments
GROUP BY NotebookId;

SELECT 
   M.Name AS ManagerName
 , NC.NotebookId AS NotebookId
 , O.ID AS OrderID
 , dbo.fnGetDatePart(O.AddDate) AS OrderDate
 , ROW_NUMBER() OVER(PARTITION BY NC.NotebookId ORDER BY dbo.fnGetDatePart(O.AddDate)) AS 'OrderNum'
INTO #Orders
FROM SRV16.RabotaUA2.dbo.NotebookCompany NC
 JOIN SRV16.RabotaUA2.dbo.Manager M ON NC.ManagerId = M.Id
 JOIN SRV16.RabotaUA2.dbo.Orders O ON NC.NotebookId = O.NotebookID
WHERE M.Id IN (156,158,159) AND O.State IN (4,5) AND O.Type IN (1,4,5);

WITH CTE AS 
(
SELECT 
   ManagerName
 , O.NotebookId
 , OrderID
 , OrderDate
 , DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.WeekNum
 , DD.WeekName
 , CASE WHEN OrderNum = 1 THEN 'Первый заказ' ELSE 'Повторный заказ' END AS 'OrderType'
 , CASE WHEN FirstPaymentDate IS NULL OR FirstPaymentDate >= OrderDate THEN 'Ранее не платили'
	ELSE 'Ранее платили' END AS 'PaymentGroup'
 , CASE 
	WHEN (SELECT COUNT(*) FROM #Orders O1 
		  WHERE O1.NotebookId = O.NotebookId
	       AND O1.OrderDate < O.OrderDate 
		   AND O1.OrderDate >= DATEADD(MONTH,-3,O.OrderDate)) > 1
	THEN 'Более 1-го заказа за последние 3 месяца'
     ELSE '1 или менее заказов за последние 3 месяца' 
   END AS 'Last3MonthOrders'
 , CASE 
	WHEN (SELECT COUNT(*) FROM #Orders O1 
		  WHERE O1.NotebookId = O.NotebookId
		   AND O1.OrderDate < O.OrderDate 
		   AND O1.OrderDate >= DATEADD(MONTH,-6,O.OrderDate)) > 1
	THEN 'Более 1-го заказа за последние 6 месяцев'
     ELSE '1 или менее заказов за последние 6 месяцев' 
   END AS 'Last6MonthOrders'
FROM #Orders O
 LEFT JOIN #FirstPayment_Dates FP ON O.NotebookId = FP.NotebookId
 JOIN Reporting.dbo.DimDate DD ON O.OrderDate = DD.Fulldate
WHERE DD.FullDate BETWEEN @StartDate AND @EndDate
)
SELECT 
   ManagerName
 , YearNum
 , MonthNum
 , MonthNameRus
 , WeekNum
 , WeekName
 , OrderType
 , PaymentGroup
 , Last3MonthOrders
 , Last6MonthOrders
 , COUNT(DISTINCT NotebookId) AS NotebookCount
FROM CTE
GROUP BY  
   ManagerName
 , YearNum
 , MonthNum
 , MonthNameRus
 , WeekNum
 , WeekName
 , OrderType
 , PaymentGroup
 , Last3MonthOrders
 , Last6MonthOrders
;

DROP TABLE #FirstPayment_Dates;
DROP TABLE #Orders;