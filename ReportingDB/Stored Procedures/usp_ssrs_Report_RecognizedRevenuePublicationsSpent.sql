CREATE PROCEDURE [dbo].[usp_ssrs_Report_RecognizedRevenuePublicationsSpent]
	@StartDate DATE, 
	@EndDate DATE

AS

-- =============================================================================================
-- Author:			michael	<michael@rabota.ua>
-- Modified date:	2016-02-26
-- Description:		Появилась необходимость разбить группу "до 10-ти вакансий" на болеее
--					мелкие группы: до 3; 4-5 вакансий; 6-10 вакансий.
--					Добавить дополнительный разрез - Тип сервиса (из DimService)
-- =============================================================================================
-- =============================================================================================
-- Author:			michael	<michael@rabota.ua>
-- Modified date:	2016-02-16
-- Description:		Заказчики изначально натупили и неправильно поставили задачу. 
--					Кол-во публикаций для группировки должно рассчитываться не в рамках 
--					указанного в отчете периода, а в пределах среднемесячного кол-ва
--					публикаций за последний год от (@EndDate - 1 год) до @EndDate
-- =============================================================================================
-- =============================================================================================
-- Author:			michael	<michael@rabota.ua>
-- Create date:		2016-02-16
-- Description:		Процедура возращает компании, у которых наблюдалось потребление платного
--					в диапазоне между @StartDate AND @EndDate, сгруппированные в зависимости
--					от кол-ва потраченных публикаций в рамках этого же периода, и с указанием
--					суммы потребления
-- =============================================================================================

BEGIN

	DECLARE @StartDateKey INT = (SELECT Date_key FROM Reporting.dbo.DimDate WHERE FullDate = @StartDate);
	DECLARE @EndDateKey INT = (SELECT Date_key FROM Reporting.dbo.DimDate WHERE FullDate = @EndDate);
	DECLARE @YearAgoDate DATE = DATEADD(YEAR, -1, @EndDate);

	-- в этом СТЕ считаем общее кол-во потраченных публикаций каждой компанией за последний год
	WITH C_NotebookSpendCount AS
	 (
	SELECT NCS.NotebookID, SUM(SpendCount) AS SumSpendCount
	FROM Analytics.dbo.NotebookCompany_Spent NCS
	WHERE EXISTS (SELECT * FROM Reporting.dbo.FactRecognizedRevenueNotebook RRN WHERE RRN.Date_key BETWEEN @StartDateKey AND @EndDateKey AND RRN.NotebookID = NCS.NotebookID)
	 AND NCS.AddDate BETWEEN @YearAgoDate AND DATEADD(DAY, 1, @EndDate)
	GROUP BY NotebookID
	 )

	SELECT 
		CASE 
		 WHEN SumSpendCount / 12. >= 50 THEN '50+'
		 WHEN SumSpendCount / 12. >= 30 THEN '30-50'
		 WHEN SumSpendCount / 12. >= 10 THEN '10-30'
		 WHEN SumSpendCount / 12. >= 6 THEN '6-10'
		 WHEN SumSpendCount / 12. >= 4 THEN '4-5'
		 ELSE 'до 3'
		END AS SpenCountGroup
	 , CASE 
		 WHEN SumSpendCount / 12. >= 50 THEN 1
		 WHEN SumSpendCount / 12. >= 30 THEN 2
		 WHEN SumSpendCount / 12. >= 10 THEN 3
		 WHEN SumSpendCount / 12. >= 6 THEN 4
		 WHEN SumSpendCount / 12. >= 4 THEN 5
		 ELSE 6
		END AS OrderNum
	 , NSC.NotebookID
	 , DC.CompanyName
	 , DC.ManagerName
	 , DS.ServiceGroup
	 , SumSpendCount
	 , SumSpendCount / 12. AS SumSpendCountMonth
	 , SUM(RRN.RecognizedRevenue) AS SumRR
	FROM C_NotebookSpendCount NSC
	 JOIN Reporting.dbo.FactRecognizedRevenueNotebook RRN ON RRN.Date_key BETWEEN @StartDateKey AND @EndDateKey AND NSC.NotebookID = RRN.NotebookID
	 JOIN Reporting.dbo.DimCompany DC ON RRN.NotebookID = DC.NotebookId
	 JOIN Reporting.dbo.DimService DS ON RRN.Service_key = DS.Service_key
	GROUP BY 	
		CASE 
		 WHEN SumSpendCount / 12. >= 50 THEN '50+'
		 WHEN SumSpendCount / 12. >= 30 THEN '30-50'
		 WHEN SumSpendCount / 12. >= 10 THEN '10-30'
		 WHEN SumSpendCount / 12. >= 6 THEN '6-10'
		 WHEN SumSpendCount / 12. >= 4 THEN '4-5'
		 ELSE 'до 3'
		END
	 , CASE 
		 WHEN SumSpendCount / 12. >= 50 THEN 1
		 WHEN SumSpendCount / 12. >= 30 THEN 2
		 WHEN SumSpendCount / 12. >= 10 THEN 3
		 WHEN SumSpendCount / 12. >= 6 THEN 4
		 WHEN SumSpendCount / 12. >= 4 THEN 5
		 ELSE 6
		END
	 , NSC.NotebookID
	 , SumSpendCount
	 , DC.CompanyName
	 , DC.ManagerName
	 , DS.ServiceGroup;

END;