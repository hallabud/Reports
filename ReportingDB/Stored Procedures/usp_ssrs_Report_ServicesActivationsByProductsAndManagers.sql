-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-02-25
-- Description:	Процедура возвращает все активированные и выполненные сервисы, которые были 
--				начислены в рамках выбранного периода, видов сервиса и менеджеров
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Modify date: 2016-07-01
-- Description:	Если сервис = 'Доступ к базе резюме', то вместо OD.Count показывать 1,
--				т.е. вместо кол-ва активированных единиц сервиса 1 факт активации
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Modify date: 2016-10-27
-- Description:	Добавлены STM-ы и тимлиды
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Modify date: 2016-10-28
-- Description:	Добавлен разрез постоянный/новый клиент
--				Добавлен разрез тип заказа (eCommerce, Обычный и др.)
-- ======================================================================================================


CREATE PROCEDURE [dbo].[usp_ssrs_Report_ServicesActivationsByProductsAndManagers]
	@StartDate DATE, @EndDate DATE, @Service VARCHAR(400), @Manager VARCHAR(400)

AS

IF OBJECT_ID('tempdb..#Payments','U') IS NOT NULL DROP TABLE #Payments;

-- временная таблица для хранения дат всех платежей компаний
SELECT NotebookID, OAP.PayDate
INTO #Payments
FROM Analytics.dbo.Order_Acc OA
 JOIN Analytics.dbo.Order_AccPayment OAP ON OA.ID = OAP.AccID AND OA.[Year] = OAP.AccYear
 JOIN Analytics.dbo.Orders ORD ON OA.OrderID = ORD.ID;

SELECT
   OD.ActivationStartDate
 , COALESCE(TL.Name, M.Name) AS TeamLead_Manager
 , COALESCE(STM.Name, M.Name) AS STM_Manager
 , M.Name AS Manager
 , NC.Name AS CompanyName
 , OS.Name AS ServiceName
 , CASE 
    WHEN EXISTS (SELECT * FROM #Payments WHERE NotebookId = O.NotebookID AND PayDate BETWEEN DATEADD(YEAR, -1, OD.ActivationStartDate) AND dbo.fnGetDatePart(OD.ActivationStartDate)) THEN 'Постоянный клиент'
	ELSE 'Новый клиент'
   END AS ClientType
 , CASE OS.Name
    WHEN 'Доступ к базе резюме' THEN 1
	ELSE OD.Count 
   END AS ActivationsCount
 , OD.UnitID
 , OD.ClientPrice
 , CASE O.Type WHEN 5 THEN 'eCommerce' ELSE 'Обычный' END AS OrderType
FROM Analytics.dbo.OrderDetail OD
 JOIN Analytics.dbo.OrderService OS ON OD.ServiceID = OS.ID
 JOIN Analytics.dbo.Orders O ON OD.OrderID = O.ID
 JOIN Analytics.dbo.NotebookCompany NC ON O.NotebookID = NC.NotebookId
 JOIN Analytics.dbo.aspnet_Membership MMB ON O.LoginEMail_OrderOwner = MMB.Email
 JOIN Analytics.dbo.Manager M ON MMB.UserId = M.aspnet_UserUIN
 LEFT JOIN Analytics.dbo.Manager STM ON M.STM_ManagerID = STM.Id
 LEFT JOIN Analytics.dbo.Manager TL ON M.TeamLead_ManagerID = TL.Id
WHERE OD.[State] IN (2,3)
 AND OD.ServiceID IN (SELECT Value FROM dbo.udf_SplitString(@Service, ','))
 AND OD.ActivationStartDate BETWEEN @StartDate AND @EndDate
 AND M.ID IN (SELECT Value FROM dbo.udf_SplitString(@Manager, ','));


