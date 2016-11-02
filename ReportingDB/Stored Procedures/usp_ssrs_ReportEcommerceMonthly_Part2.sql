
CREATE PROCEDURE [dbo].[usp_ssrs_ReportEcommerceMonthly_Part2]
AS

IF OBJECT_ID('tempdb..#EcommerceOrders','U') IS NOT NULL
 DROP TABLE #EcommerceOrders;

SELECT
   ROW_NUMBER() OVER (PARTITION BY O.NotebookId ORDER BY O.AddDate ASC) AS OrderRowNum
 , D.YearNum
 , D.MonthNum
 , D.MonthNameRus
 , D.FullDate
 , O.NotebookId
 , O.Id AS 'OrderId'
INTO #EcommerceOrders
FROM SRV16.RabotaUA2.dbo.Orders O
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC ON O.NotebookId = NC.NotebookId
 JOIN dbo.DimDate D ON dbo.fnGetDatePart(O.AddDate) = D.FullDate
WHERE NC.ManagerID IN (156,159)
 AND NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompanyMerged NCM WHERE NCM.SourceNotebookId = NC.NotebookId)
 AND O.State IN (4,5) AND O.Type IN (1,4,5);

WITH CTE AS
 (
SELECT
   YearNum
 , MonthNum
 , MonthNameRus
 , NotebookId
 , OrderID
 , OrderRowNum
 , CASE OrderRowNum WHEN 1 THEN 'Первый заказ' ELSE 'Повторный заказ' END AS OrderNumAllTime
 , (SELECT DATEDIFF(MONTH,E2.FullDate,E1.FullDate) FROM #EcommerceOrders E2 WHERE E2.NotebookId = E1.NotebookId AND E2.OrderRowNum = E1.OrderRowNum - 1) AS MonthNumFromPrevOrder
FROM #EcommerceOrders E1
 )
SELECT 
   YearNum
 , MonthNum
 , MonthNameRus
 , OrderNumAllTime
 , CASE
    WHEN MonthNumFromPrevOrder BETWEEN 0 AND 3 THEN 'Повторный заказ: в течении 3-х месяцев'
    WHEN MonthNumFromPrevOrder BETWEEN 4 AND 6 THEN 'Повторный заказ: в течении 6-ти месяцев'
    WHEN MonthNumFromPrevOrder BETWEEN 7 AND 9 THEN 'Повторный заказ: в течении 9-ти месяцев'
    WHEN MonthNumFromPrevOrder BETWEEN 10 AND 12 THEN 'Повторный заказ: в течении 12-ти месяцев'
    WHEN MonthNumFromPrevOrder > 12 THEN 'Повторный заказ: более 1 года назад'
	ELSE 'Первый заказ'
   END AS PeriodFromPrevOrder
 , COUNT(DISTINCT NotebookId) AS CompaniesNum
FROM CTE
GROUP BY 
   YearNum
 , MonthNum
 , MonthNameRus
 , OrderNumAllTime
 , CASE
    WHEN MonthNumFromPrevOrder BETWEEN 0 AND 3 THEN 'Повторный заказ: в течении 3-х месяцев'
    WHEN MonthNumFromPrevOrder BETWEEN 4 AND 6 THEN 'Повторный заказ: в течении 6-ти месяцев'
    WHEN MonthNumFromPrevOrder BETWEEN 7 AND 9 THEN 'Повторный заказ: в течении 9-ти месяцев'
    WHEN MonthNumFromPrevOrder BETWEEN 10 AND 12 THEN 'Повторный заказ: в течении 12-ти месяцев'
    WHEN MonthNumFromPrevOrder > 12 THEN 'Повторный заказ: более 1 года назад'
	ELSE 'Первый заказ'
   END;

 DROP TABLE #EcommerceOrders;

