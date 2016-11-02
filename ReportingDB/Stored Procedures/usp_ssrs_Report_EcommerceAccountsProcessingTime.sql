
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-05-26
-- Description:	Процедура возвращает список счетов по заказам с типом заказа = "eCommerce".
--				Также выводится "скорость" реакции менеджера (время в минутах от момента создания счета
--				до момента первого действия по компании после выставления счета) и "скорость" оплаты 
--				счета (время в минутах от момента выставления счета до момента первой оплаты по счету)
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-06-16
-- Description:	- СТЕ меняем на временную таблицу
--				- добавляем параметр IsRealManager (в зависимости от которого выводим резултаты
--				  по реальным менеджерам или по Лоялти группе, Татаровой и т.п.
-- ======================================================================================================

CREATE PROCEDURE [dbo].[usp_ssrs_Report_EcommerceAccountsProcessingTime]
	(@StartDate DATE, @EndDate DATE, @IsRealManager TINYINT)

AS

BEGIN

	IF OBJECT_ID('tempdb..#C','U') IS NOT NULL DROP TABLE #C;

	-- Во временную таблицу добавляем список выставленных счетов по заказам с типом = 'eCommerce'
	SELECT 
	   DD.FullDate AS InvoiceDate
	 , DD.YearNum AS InvoiceYear
	 , DD.WeekName AS InvoiceWeekName
	 , DD.WeekNum AS InvoiceWeekNum
	 , OA.AddDate AS InvoiceDT
	 , CASE 
		WHEN DD.WeekDayNum NOT IN (6,7) AND DATEPART(HOUR,OA.AddDate) BETWEEN 9 AND 17 THEN 'Рабочее' 
		ELSE 'Нерабочее'
	   END AS InvoiceWorkingTimeType
	 , O.NotebookID
	 , (SELECT TOP 1 A.CompleteDate 
		FROM Analytics.dbo.CRM_Action A 
		WHERE A.NotebookID = O.NotebookID 
		 AND A.CompleteDate >= OA.AddDate
		ORDER BY A.CompleteDate) AS FirstActionDT
	 , (SELECT TOP 1 AddDate
		FROM Analytics.dbo.Order_AccPayment OAP
		WHERE OAP.AccID = OA.ID 
		 AND OAP.AccYear = OA.Year
		ORDER BY OAP.AddDate) AS FirstPaymentDT
	 , CASE WHEN M.IsForTesting | M.IsReportExcluding | M.IsLoyaltyGroup = 1 THEN 0 WHEN M.DepartmentID <> 2 THEN 0 ELSE 1 END IsRealManager
	 , M.Name
	 , M.IsLoyaltyGroup
	INTO #C
	FROM Analytics.dbo.Order_Acc OA
	 JOIN Analytics.dbo.Orders O ON OA.OrderID = O.ID
	 JOIN Analytics.dbo.Directory D ON O.Type = D.ID AND D.Type = 'OrderType'
	 JOIN Reporting.dbo.DimDate DD ON CONVERT(DATE, OA.AddDate) = DD.FullDate
	 JOIN Analytics.dbo.aspnet_Membership MMB ON OA.LoginEMail_PaidOwner = MMB.Email
	 JOIN Analytics.dbo.Manager M ON MMB.UserId = M.aspnet_UserUIN
	WHERE D.Name = 'eCommerce'
	 AND CONVERT(DATE, OA.AddDate) BETWEEN @StartDate AND @EndDate
	 AND EXISTS (SELECT * FROM Analytics.dbo.Notebook WHERE Id = O.NotebookID AND NotebookStateId IN (5,7));

	SELECT 
	   C.*
	 , CASE
		WHEN FirstPaymentDT IS NOT NULL THEN 1
		ELSE 0
	   END AS PaymentExists
	 , CASE
		WHEN FirstActionDT IS NOT NULL AND FirstPaymentDT IS NULL THEN 'С действием'
		WHEN FirstActionDT < FirstPaymentDT THEN 'С действием'
		ELSE 'Без действия'
	   END AS InvoiceManagerActionType
	 , DATEDIFF(MINUTE, InvoiceDT, FirstActionDT) AS ManagerReactionSpeed
	 , DATEDIFF(MINUTE, InvoiceDT, FirstPaymentDT) AS PaymentSpeed
	FROM #C C
	WHERE IsRealManager IN (@IsRealManager)
	;

END