
CREATE PROCEDURE [dbo].[usp_ssrs_ReportEcommerceAccounts]
 (@StartDate DATETIME,
  @EndDate DATETIME)

AS

IF OBJECT_ID ('tempdb..#AccPaymentSum','U') IS NOT NULL DROP TABLE #AccPaymentSum;

CREATE TABLE #AccPaymentSum
 (AccYear SMALLINT NOT NULL,
  AccID INT NOT NULL,
  PaySum DECIMAL(18,2) NOT NULL,
  PRIMARY KEY (AccYear, AccID));

INSERT INTO #AccPaymentSum
SELECT AccYear, AccID, SUM(PaySum)
FROM Analytics.dbo.Order_AccPayment 
GROUP BY AccYear, AccID;

WITH C AS 
 (
SELECT 
   D.FullDate 
 , D.YearNum
 , D.MonthNum
 , D.MonthNameRus
 , D.WeekNum
 , D.WeekName
 , CASE 
	WHEN O.LoginEMail_OrderOwner IN (SELECT Email FROM Analytics.dbo.Manager WHERE DepartmentID = 3) THEN 'E-commerce'
	WHEN O.LoginEMail_OrderOwner IN (SELECT Email FROM Analytics.dbo.Manager WHERE DepartmentID = 2) THEN 'Sales Force'
    ELSE 'Other'
   END AS SalesChannel
 , CASE 
    WHEN AP.AccID IS NULL THEN 'Не оплачено'
	WHEN AP.PaySum = A.AccSum THEN 'Оплачено'
	WHEN AP.PaySum > A.AccSum THEN 'Переплачено'
	WHEN AP.PaySum < A.AccSum THEN 'Частично оплачено'
   END AS PaymentState
 , CASE 
	WHEN EXISTS (SELECT * FROM Analytics.dbo.OrderDetail WHERE OrderID = O.ID AND ServiceID = 23) THEN 'Горячая вакансия'
	WHEN EXISTS (SELECT * FROM Analytics.dbo.OrderDetail WHERE OrderID = O.ID AND ServiceID IN (63,70,71,72,73,74)) THEN 'Базовая'
    ELSE 'Другое' 
   END AS ServiceName
 , A.AccSum
 , AP.PaySum
FROM Analytics.dbo.Order_Acc A
 JOIN Reporting.dbo.DimDate D ON dbo.fnGetDatePart(A.AddDate) = D.FullDate
 JOIN Analytics.dbo.Orders O ON A.OrderID = O.ID
 LEFT JOIN #AccPaymentSum AP ON A.Year = AP.AccYear AND A.ID = AP.AccID
WHERE O.LoginEMail_OrderOwner IN (SELECT Email FROM Analytics.dbo.Manager WHERE DepartmentID IN (2,3))
AND D.FullDate BETWEEN @StartDate AND @EndDate + 1
 )
SELECT 
   YearNum
 , MonthNum
 , MonthNameRus
 , WeekNum
 , WeekName
 , SalesChannel
 , ServiceName
 , PaymentState
 , COUNT(*) AS AccNum
 , SUM(AccSum) AS SumAccSum
 , SUM(PaySum) AS SumPaySum
FROM C
GROUP BY 
   YearNum
 , MonthNum
 , MonthNameRus
 , WeekNum
 , WeekName
 , SalesChannel
 , ServiceName
 , PaymentState;

DROP TABLE #AccPaymentSum;

