
-- ========================================================================================================
-- Author:		GranovskaA <AnastasiyaG@rabota.ua>
-- Create date: 2016-10-25
-- ========================================================================================================
-- Description:	Входящие параметры процедуры
--				@StartDate - начальная дата
--				@EndDate - конечная дата
--Данные по платежам для отчета	Transaction Report Temporary
--EXECUTE usp_ssrs_Report_TransactionDataPayments @StartDate ='2016-10-01', @EndDate='2016-10-25'	
-- ========================================================================================================

CREATE PROCEDURE [dbo].[usp_ssrs_Report_TransactionDataPayments]
 @StartDate DATETIME, @EndDate DATETIME

AS

-- -------------------------------------------------
--для тестирования: вместо входящих параметров процедуры
--DECLARE @StartDate DATETIME
--DECLARE @EndDate DATETIME
--set @StartDate = '2016-10-23';
--set @EndDate   = '2016-10-25';


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

IF OBJECT_ID('tempdb..#Managers') IS NOT NULL DROP TABLE #Managers
SELECT 
	m.Id AS ManagerID
 	, m.Name AS ManagerName 
	, MMB.LoweredEmail AS Email
INTO #Managers
FROM SRV16.RabotaUA2.dbo.Manager M
	JOIN SRV16.RabotaUA2.dbo.aspnet_Membership MMB ON M.aspnet_UserUIN = MMB.UserId
WHERE 1=1
    --AND DepartmentID IN (12)
	AND m.Id in (318,320,328,337,340) 




SELECT isnull(x.ServiceName,'Optimum') AS ServiceName,
m.ManagerName,m.ManagerID,
isnull(x.NotebookID,0) AS NotebookID,
ISNULL(PaymentNumver,0) AS PaymentNumver,
isnull(PaySum,0) as PaySum
from #Managers m
LEFT join
(
SELECT y.ServiceName,y.ManagerName,y.ManagerID, y.NotebookID, count(y.id) AS PaymentNumver, sum(y.ClientPrice) AS PaySum -- OD.ClientPrice
FROM 
(
SELECT DISTINCT OS.Name AS ServiceName,m.ManagerName,m.ManagerID, o.NotebookID, OAP.id, od.ClientPrice
FROM 
SRV16.RabotaUA2.dbo.Order_AccPayment OAP
 JOIN SRV16.RabotaUA2.dbo.Order_Acc OA ON OAP.AccID = OA.ID AND OAP.AccYear = OA.Year
 JOIN SRV16.RabotaUA2.dbo.Orders O ON OA.OrderID = O.ID
 JOIN SRV16.RabotaUA2.dbo.OrderDetail OD ON O.ID = OD.OrderID
 JOIN SRV16.RabotaUA2.dbo.OrderService OS ON OD.ServiceID = OS.ID
 right JOIN #Managers m ON m.Email = OA.LoginEMail_PaidOwner 
WHERE 
 OAP.PayDate BETWEEN @StartDate and @EndDate + 1
 ) y GROUP BY y.ServiceName,y.ManagerName,y.ManagerID, y.NotebookID

) x ON m.ManagerID = x.ManagerID




--SELECT isnull(x.ServiceName,'Optimum') AS ServiceName,
--m.ManagerName,m.ManagerID,
--isnull(x.NotebookID,0) AS NotebookID,
--ISNULL(PaymentNumver,0) AS PaymentNumver,
--isnull(PaySum,0) as PaySum
--from #Managers m
--LEFT join
--(
--SELECT OS.Name AS ServiceName,m.ManagerName,m.ManagerID, o.NotebookID, count(OAP.id) AS PaymentNumver, sum(oap.PaySum) AS PaySum -- OD.ClientPrice
--FROM 
--SRV16.RabotaUA2.dbo.Order_AccPayment OAP
-- JOIN SRV16.RabotaUA2.dbo.Order_Acc OA ON OAP.AccID = OA.ID AND OAP.AccYear = OA.Year
-- JOIN SRV16.RabotaUA2.dbo.Orders O ON OA.OrderID = O.ID
-- JOIN SRV16.RabotaUA2.dbo.OrderDetail OD ON O.ID = OD.OrderID
-- JOIN SRV16.RabotaUA2.dbo.OrderService OS ON OD.ServiceID = OS.ID
-- right JOIN #Managers m ON m.Email = OA.LoginEMail_PaidOwner 
--WHERE 
-- OAP.PayDate BETWEEN @StartDate and @EndDate + 1
--GROUP BY OS.Name, o.NotebookID ,m.ManagerName,m.ManagerID  

--) x ON m.ManagerID = x.ManagerID


--SELECT x.ServiceName,x.ManagerName,x.ManagerID, x.NotebookID, count(x.id) AS PaymentNumver, sum(x.ClientPrice) AS PaySum -- OD.ClientPrice
--FROM 
--(
--SELECT DISTINCT OS.Name AS ServiceName,m.ManagerName,m.ManagerID, o.NotebookID, OAP.id, od.ClientPrice 	
--from SRV16.RabotaUA2.dbo.Order_AccPayment OAP
-- JOIN SRV16.RabotaUA2.dbo.Order_Acc OA ON OAP.AccID = OA.ID AND OAP.AccYear = OA.Year
-- JOIN SRV16.RabotaUA2.dbo.Orders O ON OA.OrderID = O.ID
-- JOIN SRV16.RabotaUA2.dbo.OrderDetail OD ON O.ID = OD.OrderID
-- JOIN SRV16.RabotaUA2.dbo.OrderService OS ON OD.ServiceID = OS.ID
-- right JOIN #Managers m ON m.Email = OA.LoginEMail_PaidOwner 
--WHERE 
-- OAP.PayDate BETWEEN '2016-10-10 00:00:00.000' AND '2016-10-23 00:00:00.000'
--  AND m.ManagerID = 318
-- AND oap.id=1196235
-- ) x GROUP BY x.ServiceName,x.ManagerName,x.ManagerID, x.NotebookID