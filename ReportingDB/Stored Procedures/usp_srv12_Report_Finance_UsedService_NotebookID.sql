CREATE PROCEDURE [dbo].[usp_srv12_Report_Finance_UsedService_NotebookID] (
	@DateFrom DATETIME,
	@DateTo DATETIME
)
/**************************************************************************************************
 MODIFIED BY:	Mikhail Abdulakh
 MODIFIED ON:	08.10.2013
 COMMENTS	:	Изменен принцип расчета суммы использованного сервиса по CVDB.
***************************************************************************************************
 MODIFIED BY:	Andrew Smiyan
 MODIFIED ON:	11.03.2013
 COMMENTS	:	Добавлена информация о неиспользованных (сгоревших) публикациях.
***************************************************************************************************
 CREATED BY	:	Andrew Smiyan
 CREATED ON	:	16.11.2012
 COMMENTS	:	Task #9572.
***************************************************************************************************/
AS
BEGIN

	SET NOCOUNT ON

	DECLARE @DayFrom SMALLINT
	DECLARE @DayTo SMALLINT

	SET @DayFrom = dbo.fnDayByDate(@DateFrom)
	SET @DayTo = dbo.fnDayByDate(@DateTo)

	SET @DateTo = DATEADD(S, -1, dbo.fnGetDatePart(@DateTo) + 1)

	DECLARE @ExceptNotebooks TABLE (NotebookID INT)

	/* блокноты, по которым не считается Recognized Revenue */
	INSERT INTO @ExceptNotebooks (NotebookID)
	SELECT 285271
	UNION ALL
	SELECT 853455
	UNION ALL
	SELECT 205674
	UNION ALL
	SELECT 632165
	UNION ALL
	SELECT N.ID
	FROM SRV16.RabotaUA2.dbo.Notebook N WITH (NOLOCK)
		JOIN SRV16.RabotaUA2.dbo.aspnet_Membership M WITH (NOLOCK) ON M.UserID = N.aspnet_UserUIN
	WHERE M.EMail IN ('admin@rastishka.ua', 'hr@rastishka.ua', 'testrua2@gmail.com', 
		'scenariounreg10@ukr.net', 'scenariounreg15@ukr.net',
		'scenariounreg14@ukr.net', 'scenariounreg16@ukr.net',
		'hr@massivedynamic.com', 'rec@massivedynamic.com')
	/* **************************************************** */

	/* временная таблица - справочник типов потраченных сервисов, которые определяются по потраченным тикетам  */
	SELECT 1 AS ID, 'Standard' AS Name, 0 AS RegionalPackageID
	INTO #SpentType
	UNION ALL
	SELECT 2 AS ID, 'Professional' AS Name, 0 AS RegionalPackageID
	UNION ALL
	SELECT 3 AS ID, 'VIP' AS Name, 0 AS RegionalPackageID
	UNION ALL
	SELECT 4 AS ID, Name, PackageID AS RegionalPackageID
	FROM SRV16.RabotaUA2.dbo.RegionalPackage WITH (NOLOCK)
	WHERE PackageID IN (16, 18)
	UNION ALL
	SELECT 5 AS ID, 'Hot' AS Name, 0 AS RegionalPackageID
	/* **************************************************** */

	SELECT NotebookID, TicketPaymentID, SpendCount AS Quantity, 
		SpendType, RegionalPackageID, OrderID, 0 AS IsFire
	INTO #Spent
	FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent A WITH (NOLOCK)
	WHERE AddDate BETWEEN @DateFrom AND @DateTo
		AND NOT EXISTS(SELECT * FROM @ExceptNotebooks WHERE NotebookID = A.NotebookID)
	UNION ALL
	SELECT NotebookID, TicketPaymentID, TicketAwayCount AS Quantity, 
		TicketType AS SpendType, RegionalPackageID, OrderID, IsFire
	FROM SRV16.RabotaUA2.dbo.TicketAway A WITH (NOLOCK)
	WHERE AddDate BETWEEN @DateFrom AND @DateTo
		AND NOT EXISTS(SELECT * FROM @ExceptNotebooks WHERE NotebookID = A.NotebookID)

	SELECT S.NotebookId, S.SpendType, ISNULL(S.RegionalPackageID, 0) AS RegionalPackageID, S.Quantity, 
		CASE 
			WHEN S.SpendType = 1
				THEN CASE WHEN P.VacancyStandart = 0 THEN 0. ELSE 1. * P.SummStandart / P.VacancyStandart END
			WHEN S.SpendType = 2
				THEN CASE WHEN P.VacancyDesigned = 0 THEN 0. ELSE 1. * P.SummDesigned / P.VacancyDesigned END
			WHEN S.SpendType = 3
				THEN CASE WHEN P.VacancyVIP = 0 THEN 0. ELSE 1. * P.SummVIP / P.VacancyVIP END
			WHEN S.SpendType = 5
				THEN CASE WHEN P.VacancyHot = 0 THEN 0. ELSE 1. * P.SummHot / P.VacancyHot END
		END AS Price,
		CASE WHEN S.OrderID IS NULL THEN 1.2 ELSE 1. END AS VatCoef,
		S.IsFire
	INTO #SpentList
	FROM #Spent S
		JOIN SRV16.RabotaUA2.dbo.TicketPayment P WITH (NOLOCK) ON P.ID = S.TicketPaymentID
	WHERE S.RegionalPackageID IS NULL
	UNION ALL
	SELECT S.NotebookId, S.SpendType, S.RegionalPackageID, S.Quantity, 
		CASE WHEN P.TicketCount = 0 THEN 0. ELSE 1. * P.TicketSumm / P.TicketCount END AS Price,
		CASE WHEN S.OrderID IS NULL THEN 1.2 ELSE 1. END AS VatCoef,
		S.IsFire
	FROM #Spent S
		JOIN SRV16.RabotaUA2.dbo.RegionalTicketPayment P WITH (NOLOCK) ON P.ID = S.TicketPaymentID
	WHERE S.RegionalPackageID IS NOT NULL

	DECLARE @Result TABLE (ID INT, NotebookID INT, Name VARCHAR(255), Sum DECIMAL(18, 2))

	INSERT INTO @Result (ID, Name, NotebookID, Sum)
	SELECT CASE WHEN ST.ID = 4 AND ST.RegionalPackageID = 16 THEN 4 WHEN ST.ID = 4 AND ST.RegionalPackageID = 18 THEN 5 WHEN ST.ID = 5 THEN 6 ELSE ST.ID END AS ID
	 , ST.Name, A.NotebookID, ISNULL(SUM(CONVERT(DECIMAL(18, 2), A.Quantity * A.Price / A.VatCoef)), 0) AS Sum
	FROM #SpentType ST
		LEFT JOIN #SpentList A ON ST.ID = A.SpendType AND ST.RegionalPackageID = A.RegionalPackageID AND A.IsFire = 0
	GROUP BY ST.ID, ST.Name, ST.ID, ST.RegionalPackageID, A.NotebookID
	HAVING ISNULL(SUM(CONVERT(DECIMAL(18, 2), A.Quantity * A.Price / A.VatCoef)), 0) > 0
	ORDER BY ST.ID, ST.RegionalPackageID, A.NotebookID
	
	INSERT INTO @Result (ID, NotebookID, Name, Sum)
	SELECT 7 AS ID, O.NotebookID, 'CVDB' AS Name
	 , ISNULL(SUM(CAST(ClientPrice * dbo.fnGetPeriodIntersection(dbo.fnDayByDate(ActivationStartDate), dbo.fnDayByDate(ActivationEndDate), dbo.fnDayByDate(@DateFrom), dbo.fnDayByDate(@DateTo)) AS DECIMAL(18,2))),0) AS Sum
	FROM SRV16.RabotaUA2.dbo.OrderDetail OD WITH (NOLOCK)
	 JOIN SRV16.RabotaUA2.dbo.Orders O WITH (NOLOCK) ON OD.OrderID = O.ID
	WHERE OD.ServiceID IN (4,144)  AND ClientPrice > 0
	 AND O.State IN (4,5) AND O.Type IN (1,5)
	 AND O.NotebookId NOT IN (SELECT NotebookID FROM @ExceptNotebooks)
	 AND OD.ActivationStartDate <= @DateTo AND OD.ActivationEndDate >= @DateFrom
	GROUP BY O.NotebookID
	UNION ALL
	SELECT 8 AS ID, NotebookID, 'Company Profile' AS Name, 
		ISNULL(SUM(CONVERT(DECIMAL(18, 2), Total * dbo.fnGetPeriodIntersection(DateFrom, DateTo, @DayFrom, @DayTo) / CASE WHEN OrderID IS NULL THEN 1.2 ELSE 1 END)), 0) AS Sum
	FROM SRV16.RabotaUA2.dbo.NotebookPaymentPeriod A WITH (NOLOCK)
	WHERE Total <> 0 AND State = 10 AND NotebookPaymentTypeID = 14
		AND DateFrom <= @DayTo AND DateTo >= @DayFrom
		AND NOT EXISTS(SELECT * FROM @ExceptNotebooks WHERE NotebookID = A.NotebookID)
	GROUP BY NotebookID
	UNION ALL
	SELECT 9 AS ID, NotebookID, 'Logotype' AS Name, 
		ISNULL(SUM(CONVERT(DECIMAL(18, 2), Total * dbo.fnGetPeriodIntersection(DateFrom, DateTo, @DayFrom, @DayTo) / CASE WHEN OrderID IS NULL THEN 1.2 ELSE 1 END)), 0) AS Sum
	FROM SRV16.RabotaUA2.dbo.NotebookPaymentPeriod A WITH (NOLOCK)
	WHERE Total <> 0 AND State = 10 
		AND (NotebookPaymentTypeID = 12 OR NotebookPaymentTypeID BETWEEN 15 AND 23)
		AND DateFrom <= @DayTo AND DateTo >= @DayFrom
		AND NOT EXISTS(SELECT * FROM @ExceptNotebooks WHERE NotebookID = A.NotebookID)
	GROUP BY NotebookID

	INSERT INTO @Result (ID, NotebookID, Name, Sum)
	SELECT 10 AS ID, NotebookID, 'Неиспользованные публикации' AS Name, ISNULL(SUM(CONVERT(DECIMAL(18, 2), Quantity * Price / VatCoef)), 0) AS Sum
	FROM #SpentList
	WHERE IsFire = 1
	GROUP BY NotebookID
	HAVING ISNULL(SUM(CONVERT(DECIMAL(18, 2), Quantity * Price / VatCoef)), 0) > 0

	SELECT ID, NotebookID, Name, SUM(Sum) AS Sum FROM @Result GROUP BY ID, NotebookID, Name ORDER BY ID, NotebookID

	DROP TABLE #SpentType
	DROP TABLE #Spent
	DROP TABLE #SpentList

END