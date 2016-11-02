-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Modify date: 2016-07-14
-- Description:	добавлены новые диапазони RevenueGroup - 500K+ и 300K - 500K
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Modify date: 2016-02-08
-- Description:	Добавлены параметры @StartDate и @EndDate
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-02-08
-- Description:	Процедура возвращает суммы "потребления" по каждому менеджеру помесячно. 
--				В зависимости от суммы "потребления" проставляется RevenueGroup
--				Период времени - последние 12 полных месяцев
-- ======================================================================================================
CREATE PROCEDURE [dbo].[usp_ssrs_Report_RecognizedRevenuesMangersCountByRevenueGroups] 
	@StartDate DATE, @EndDate DATE

AS


SELECT 
   DD.YearNum
 , DD.MonthNum
 , DD.MonthNameEng
 , DC.ManagerName
 , SUM(RRN.RecognizedRevenue) AS SumRR
 , CASE
    WHEN SUM(RRN.RecognizedRevenue) >= 500000 THEN '500K+'
	WHEN SUM(RRN.RecognizedRevenue) >= 300000 THEN '300K - 500K'
	WHEN SUM(RRN.RecognizedRevenue) >= 200000 THEN '200K - 300K'
	WHEN SUM(RRN.RecognizedRevenue) >= 100000 THEN '100K - 200K'
	WHEN SUM(RRN.RecognizedRevenue) >= 50000 THEN '50K - 100K'
	WHEN SUM(RRN.RecognizedRevenue) >= 25000 THEN '25K - 50K'
	ELSE '< 25K'
   END AS RevenueGroup
FROM Reporting.dbo.FactRecognizedRevenueNotebook RRN
 JOIN Reporting.dbo.DimCompany DC ON RRN.NotebookID = DC.NotebookId
 JOIN Reporting.dbo.DimDate DD ON RRN.Date_key = DD.Date_key
WHERE DD.FullDate BETWEEN @StartDate AND @EndDate
GROUP BY 
   DD.YearNum
 , DD.MonthNum
 , DD.MonthNameEng
 , DC.ManagerName
ORDER BY 
   YearNum
 , MonthNum
 , SumRR
