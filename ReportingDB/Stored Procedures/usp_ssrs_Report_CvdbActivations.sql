
-- =============================================================================================
-- Author:		michael	<michael@rabota.ua>
-- Create date: 2016-02-19
-- Description:	Процедура возращает количество активаций доступа к базе резюме, 
--				сгруппированных по дням в разрезе платности севриса. 
-- =============================================================================================

CREATE PROCEDURE [dbo].[usp_ssrs_Report_CvdbActivations]
	@StartDate DATE, @EndDate DATE

AS

BEGIN
	
	IF OBJECT_ID('tempdb..#CvdbOrders') IS NOT NULL DROP TABLE #CvdbOrders;

	SELECT 
		OD.OrderID
		, OD.ID AS OrderDetailID
		, Dir.Name AS OrderType
		, CASE
		WHEN ClientPrice > 0 THEN 'платный'
		ELSE 'бесплатный'
		END AS OrderPayType
		, OD.ClientPrice
		, O.NotebookID
		, DD.YearNum
		, DD.QuarterNum
		, DD.MonthNum
		, DD.MonthNameEng
		, DD.WeekNum
		, DD.WeekName
		, DD.FullDate
	INTO #CvdbOrders
	FROM Analytics.dbo.OrderDetail OD
		JOIN Analytics.dbo.Orders O ON OD.OrderID = O.ID
		JOIN Analytics.dbo.Directory Dir ON O.Type = Dir.ID AND Dir.Type = 'OrderType'
		JOIN Reporting.dbo.DimDate DD ON OD.ActivationStartDate = DD.FullDate
	WHERE OD.ServiceID = 4 -- Сервис = доступ к базе резюме
	 AND OD.[State] IN (2,3)
	 AND OD.ActivationStartDate BETWEEN @StartDate AND @EndDate; -- Статус - активирован, выполнен

	 
	SELECT YearNum, WeekNum, WeekName, FullDate, 'Все заказы' AS OrderPayType, COUNT(*) AS ActivationsCount
	FROM #CvdbOrders
	GROUP BY YearNum, WeekNum, WeekName, FullDate

	UNION ALL

	SELECT YearNum, WeekNum, WeekName, FullDate, OrderPayType, COUNT(*) 
	FROM #CvdbOrders
	GROUP BY YearNum, WeekNum, WeekName, FullDate, OrderPayType;

	DROP TABLE #CvdbOrders;

END;