
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-06-02
-- Description:	Процедура возвращает список потраченных горячих публикаций с расчитанной стоимостью
-- ======================================================================================================

CREATE PROCEDURE dbo.usp_ssrs_Report_HotRegularVsRegional
	(@StartDate DATE, @EndDate DATE, @ManagerIDs NVARCHAR(1000))

AS

SELECT 
   NCS.ID
 , DD.YearNum
 , DD.MonthNum
 , DD.MonthNameEng
 , NCS.NotebookID
 , CASE WHEN OS.Name LIKE '%регион%' THEN 'Региональная горячая' ELSE 'Горячая' END AS ServiceName
 , NCS.SpendCount * CONVERT(DECIMAL(16,2), 1. * SummHot / VacancyHot) AS Revenue
FROM Analytics.dbo.NotebookCompany_Spent NCS
 JOIN Analytics.dbo.TicketPayment TP ON NCS.TicketPaymentID = TP.Id
 JOIN Analytics.dbo.OrderDetail OD ON TP.OrderDetailID = OD.ID
 JOIN Analytics.dbo.OrderService OS ON OD.ServiceID = OS.ID
 JOIN Analytics.dbo.Orders O ON OD.OrderID = O.ID
 JOIN Analytics.dbo.NotebookCompany NC ON O.NotebookID = NC.NotebookID
 JOIN Reporting.dbo.DimDate DD ON CONVERT(DATE, NCS.AddDate) = DD.FullDate
WHERE DD.FullDate BETWEEN @StartDate AND @EndDate
 AND NCS.SpendType = 5
 AND NC.ManagerId IN (SELECT Value FROM Reporting.dbo.udf_SplitString(@ManagerIDs,','));
