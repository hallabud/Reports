

CREATE PROCEDURE [dbo].[usp_ssrs_Report_Forecast_bak] (@StartDate DATETIME, @EndDate DATETIME)

AS

SET NOCOUNT ON

IF OBJECT_ID('tempdb..#Payments','U') IS NOT NULL DROP TABLE #Payments;
IF OBJECT_ID('tempdb..#AccountStates','U') IS NOT NULL DROP TABLE #AccountStates;

CREATE TABLE #AccountStates (AccYear INT, AccID INT, AccSum DECIMAL(10,2), PaySum DECIMAL(10,2), AccState VARCHAR(20));
CREATE TABLE #Payments (DealID INT, OrderID INT, NotebookID INT, LoginEMail_DealOwner VARCHAR(200), PaymentDate DATETIME, PaymentSum DECIMAL(10,2));

--DECLARE @StartDate DATETIME; SET @StartDate = '2014-04-01';
--DECLARE @EndDate DATETIME; SET @EndDate = '2014-04-30';

INSERT INTO #AccountStates
SELECT 
   OA.Year AS AccYear
 , OA.ID AS AccID
 , AccSum AS AccSum
 , ISNULL(SumPaySum,0) AS PaySum  
 , CASE 
    WHEN AccSum - ISNULL(SumPaySum,0) = 0 THEN 'Оплачен'
	WHEN AccSum - ISNULL(SumPaySum,0) = AccSum THEN 'Не оплачен'
	WHEN AccSum - ISNULL(SumPaySum,0) < AccSum THEN 'Частично оплачен'
   END AS AccState
FROM SRV16.RabotaUA2.dbo.Order_Acc OA WITH (NOLOCK)
 LEFT JOIN 
  (SELECT AccYear, AccID, SUM(PaySum) AS SumPaySum
   FROM SRV16.RabotaUA2.dbo.Order_AccPayment WITH (NOLOCK)
   GROUP BY AccYear, AccID) OAP ON OA.Year = OAP.AccYear AND OA.ID = OAP.AccID;

DECLARE @DealID INT, @OrderId INT, @NotebookID INT, @LoginEMail_DealOwner VARCHAR(200), @ClientPriceSum DECIMAL(10,2), @FirstPaymentDate DATETIME, @PaymentDuration INT, @PaymentInterval INT, @PaymentNum INT;
DECLARE @payment_ordnum INT;

DECLARE deals_cursor CURSOR FOR
SELECT 
   D.ID AS DealID
 , O.ID AS OrderID
 , O.NotebookID
 , D.LoginEMail_DealOwner
 , O.ClientPriceSum
 , D.FirstPaymentDate
 , CASE 
    WHEN EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.OrderDetail WHERE OrderID = O.ID AND UnitID = 6) THEN 12 * 30
	WHEN EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.OrderDetail WHERE OrderID = O.ID AND UnitID = 3) 
	 THEN (SELECT MAX(Count) FROM SRV16.RabotaUA2.dbo.OrderDetail WHERE OrderID = O.ID AND UnitID = 3) * 3 * 30
   END AS PaymentDuration
 , CASE O.PaymentVariantID
    WHEN 3 THEN 1 * 30
	WHEN 4 THEN 3 * 30
	WHEN 5 THEN 6 * 30
   END AS PaymentInterval
 , CASE 
    WHEN EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.OrderDetail WHERE OrderID = O.ID AND UnitID = 6) THEN 12 * 30
	WHEN EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.OrderDetail WHERE OrderID = O.ID AND UnitID = 3) 
	 THEN (SELECT MAX(Count) FROM SRV16.RabotaUA2.dbo.OrderDetail WHERE OrderID = O.ID AND UnitID = 3) * 3 * 30
   END
 / CASE O.PaymentVariantID
    WHEN 3 THEN 1 * 30
	WHEN 4 THEN 3 * 30
	WHEN 5 THEN 6 * 30
   END PaymentNum
FROM SRV16.RabotaUA2.dbo.Orders O WITH (NOLOCK)
 JOIN (SELECT OrderID, MAX(CASE UnitID WHEN 6 THEN 12 * 30 WHEN 3 THEN Count * 3 * 30 WHEN 2 THEN Count * 30 WHEN 1 THEN Count * 7 END) AS Duration
	    FROM SRV16.RabotaUA2.dbo.OrderDetail WITH (NOLOCK)
		GROUP BY OrderID) OD ON O.ID = OD.OrderID
 JOIN SRV16.RabotaUA2.dbo.CRM_Deal D WITH (NOLOCK) ON O.DealID = D.ID
WHERE O.DealID IS NOT NULL AND O.IsDealMain = 1 AND D.StateID = 1 AND O.Type <> 5 AND PaymentVariantID IN (3,4,5);

OPEN deals_cursor;
 
 FETCH NEXT FROM deals_cursor INTO @DealID, @OrderId, @NotebookID, @LoginEMail_DealOwner, @ClientPriceSum, @FirstPaymentDate, @PaymentDuration, @PaymentInterval, @PaymentNum;

 WHILE @@FETCH_STATUS = 0
 BEGIN 
	SET @payment_ordnum = 1

	WHILE @payment_ordnum <= @PaymentNum
	BEGIN
		INSERT INTO #Payments SELECT @DealID, @OrderId, @NotebookID, @LoginEMail_DealOwner, DATEADD(DAY, (@payment_ordnum - 1) * @PaymentInterval, @FirstPaymentDate), @ClientPriceSum / @PaymentNum
		SET @payment_ordnum = @payment_ordnum + 1;
	END;

	FETCH NEXT FROM deals_cursor INTO @DealID, @OrderId, @NotebookID, @LoginEMail_DealOwner, @ClientPriceSum, @FirstPaymentDate, @PaymentDuration, @PaymentInterval, @PaymentNum;
 END;

CLOSE deals_cursor;
DEALLOCATE deals_cursor;

WITH C_Deals AS 
 (
SELECT 
   P.LoginEMail_DealOwner AS Manager
 , P.DealID
 , P.OrderID
 , Dir1.Name AS ForecastGroup
 , Dir1.OrderNumber AS ForecastGroupOrderNum
 , NC.Name AS CompanyName
 , P.PaymentDate
 , P.PaymentSum
 , D.ClosePossibility
 , CAST(P.PaymentSum * ISNULL(D.ClosePossibility, 100.) / 100. AS DECIMAL(10,2)) AS PosPaymentSum   --, P.* 
FROM #Payments P
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC WITH (NOLOCK) ON P.NotebookID = NC.NotebookID
 JOIN SRV16.RabotaUA2.dbo.CRM_Deal D WITH (NOLOCK) ON P.DealID = D.ID
 JOIN SRV16.RabotaUA2.dbo.CRM_Directory Dir1 WITH (NOLOCK) ON D.StageId = Dir1.ID AND Dir1.Type = 'DealStage'
WHERE PaymentDate >= @StartDate AND PaymentDate < @EndDate + 1
 )
-- форкаст - счета - оплаченные
 , C_Accounts_Paid AS
 (
SELECT 
   OA.LoginEMail_PaidOwner AS Manager
 , NULL AS DealID
 , O.ID AS OrderID
 , CASE 
    WHEN O.State IN (2,3) AND OAS.AccState <> 'Оплачен' THEN 'Заказ сформирован - контроль оплаты'
	WHEN O.State IN (2,3) AND OAS.AccState = 'Оплачен' THEN 'Заказ сформирован - счет оплачен'
	WHEN O.State IN (4,5) AND OAS.AccState <> 'Оплачен' THEN 'Заказ активирован - контроль оплаты'
	WHEN O.State IN (4,5) AND OAS.AccState = 'Оплачен' THEN 'Заказ активирован - счет оплачен'
   END AS ForecastGroup
 , 9 AS ForecastGroupOrderNum
 , NC.Name AS CompanyName
 , Analytics.dbo.fnGetDatePart(OAP.PayDate) AS AccDate
 , OAP.PaySum AS AccSum
 , 100 AS Possibility
 , OAP.PaySum AS PosAccSum
FROM SRV16.RabotaUA2.dbo.Order_Acc OA WITH (NOLOCK)
 JOIN SRV16.RabotaUA2.dbo.Order_AccPayment OAP WITH (NOLOCK) ON OA.Year = OAP.AccYear AND OA.ID = OAP.AccID
 JOIN #AccountStates OAS ON OA.Year = OAS.AccYear AND OA.ID = OAS.AccID
 JOIN SRV16.RabotaUA2.dbo.Orders O WITH (NOLOCK) ON OA.OrderID = O.Id
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC WITH (NOLOCK) ON O.NotebookID = NC.NotebookID
WHERE ISNULL(OA.LoginEMail_PaidOwner, '') <> '' AND OAS.AccState = 'Оплачен' AND O.State IN (2,3,4,5)
 AND OAP.PayDate >= @StartDate AND OAP.PayDate < @EndDate + 1
 )
 -- форкаст - счета - частично оплаченные
 , C_Accounts_Paid_Partly AS
 (
SELECT 
   OA.LoginEMail_PaidOwner AS Manager
 , NULL AS DealID
 , O.ID AS OrderID
 , CASE 
	WHEN O.State IN (2,3) AND OAS.AccState = 'Частично оплачен' THEN 'Заказ сформирован - счет оплачен'
	WHEN O.State IN (4,5) AND OAS.AccState = 'Частично оплачен' THEN 'Заказ активирован - счет оплачен'
   END AS ForecastGroup
 , 9 AS ForecastGroupOrderNum
 , NC.Name AS CompanyName
 , Analytics.dbo.fnGetDatePart(OAP.PayDate) AS AccDate
 , OAP.PaySum AS AccSum
 , 100 AS Possibility
 , OAP.PaySum AS PosAccSum
FROM SRV16.RabotaUA2.dbo.Order_Acc OA WITH (NOLOCK)
 JOIN SRV16.RabotaUA2.dbo.Order_AccPayment OAP WITH (NOLOCK) ON OA.Year = OAP.AccYear AND OA.ID = OAP.AccID
 JOIN #AccountStates OAS WITH (NOLOCK) ON OA.Year = OAS.AccYear AND OA.ID = OAS.AccID
 JOIN SRV16.RabotaUA2.dbo.Orders O WITH (NOLOCK) ON OA.OrderID = O.Id
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC WITH (NOLOCK) ON O.NotebookID = NC.NotebookID
WHERE ISNULL(OA.LoginEMail_PaidOwner, '') <> '' AND OAS.AccState = 'Частично оплачен' AND O.State IN (2,3,4,5)
 AND OAP.PayDate >= @StartDate AND OAP.PayDate < @EndDate + 1
 )
 -- форкаст - счета - остаток к оплате по непоплаченным или частично оплаченным счетам
 , C_Accounts_NotPaid AS
 (
SELECT 
   OA.LoginEMail_PaidOwner AS Manager
 , NULL AS DealID
 , O.ID AS OrderID
 , CASE 
    WHEN O.State IN (2,3) AND OAS.AccState <> 'Оплачен' THEN 'Заказ сформирован - контроль оплаты'
	WHEN O.State IN (2,3) AND OAS.AccState = 'Оплачен' THEN 'Заказ сформирован - счет оплачен'
	WHEN O.State IN (4,5) AND OAS.AccState <> 'Оплачен' THEN 'Заказ активирован - контроль оплаты'
	WHEN O.State IN (4,5) AND OAS.AccState = 'Оплачен' THEN 'Заказ активирован - счет оплачен'
   END AS ForecastGroup
 , 9 AS ForecastGroupOrderNum
 , NC.Name AS CompanyName
 , Analytics.dbo.fnGetDatePart(OA.AccDate) AS AccDate
 , OA.AccSum - OAS.PaySum AS AccSum
 , OA.Possibility AS Possibility
 , CAST((OA.AccSum - OAS.PaySum) * ISNULL(OA.Possibility, 100) / 100. AS DECIMAL(10,2)) AS PosAccSum
FROM SRV16.RabotaUA2.dbo.Order_Acc OA WITH (NOLOCK)
 JOIN #AccountStates OAS ON OA.Year = OAS.AccYear AND OA.ID = OAS.AccID
 JOIN SRV16.RabotaUA2.dbo.Orders O WITH (NOLOCK) ON OA.OrderID = O.Id
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC WITH (NOLOCK) ON O.NotebookID = NC.NotebookID
WHERE ISNULL(OA.LoginEMail_PaidOwner, '') <> '' AND OAS.AccState <> 'Оплачен' AND O.State IN (2,3,4,5)
 AND OA.AccDate >= @StartDate AND OA.AccDate < @EndDate + 1
 )
-- форкаст - сделки со 100% предоплатой или постоплатой
 , C_Deals_100Prc AS
 (
SELECT 
   D.LoginEMail_DealOwner AS Manager
 , D.ID AS DealID
 , O.ID AS OrderID
 , Dir1.Name AS ForecastGroup
 , Dir1.OrderNumber AS ForecastGroupOrderNum
 , NC.Name AS CompanyName
 , D.FirstPaymentDate
 , SUM(O.ClientPriceSum) AS ClientPriceSum
 , D.ClosePossibility
 , SUM(CAST(ISNULL(D.ClosePossibility, 100) * O.ClientPriceSum / 100. AS DECIMAL(10,2))) AS PosClientPriceSum
FROM SRV16.RabotaUA2.dbo.CRM_Deal D WITH (NOLOCK)
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC WITH (NOLOCK) ON D.NotebookID = NC.NotebookID
 JOIN SRV16.RabotaUA2.dbo.Orders O WITH (NOLOCK) ON D.ID = O.DealID
 JOIN SRV16.RabotaUA2.dbo.CRM_Directory Dir1 WITH (NOLOCK) ON  Dir1.Type = 'DealStage' AND D.StageID = Dir1.ID
WHERE ISNULL(D.LoginEMail_DealOwner, '') <> ''
 AND O.IsDealMain = 1
 AND FirstPaymentDate >= @StartDate AND FirstPaymentDate < @EndDate + 1 
 AND PaymentVariantID IN (1,2)
 AND D.StateID = 1
GROUP BY  
   D.LoginEMail_DealOwner
 , D.ID
 , O.ID
 , Dir1.Name
 , Dir1.OrderNumber
 , NC.Name
 , D.FirstPaymentDate
 , D.ClosePossibility
 )
SELECT * FROM C_Accounts_Paid
UNION ALL
SELECT * FROM C_Accounts_Paid_Partly
UNION ALL
SELECT * FROM C_Accounts_NotPaid
UNION ALL
SELECT * FROM C_Deals_100Prc
UNION ALL
SELECT * FROM C_Deals;

DROP TABLE #Payments;

