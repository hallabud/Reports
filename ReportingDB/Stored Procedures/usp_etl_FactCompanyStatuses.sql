
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: NULL
-- Description:	Процедура считает ряд показателей и инсертит их в таблицу FactCompanyStatuses
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Modify date: 2016-10-19
-- Description:	Добавлено грязное чтение. 
--				Обращение к таблице VacancyPublishHistory заменено на NotebookCompany_Spent
-- ======================================================================================================


CREATE PROCEDURE [dbo].[usp_etl_FactCompanyStatuses]

AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @TodayDate DATETIME; SET @TodayDate = dbo.fnGetDatePart(GETDATE());
DECLARE @Yesterday DATETIME; SET @Yesterday = dbo.fnGetDatePart(DATEADD(DAY,-1,GETDATE()));
DECLARE @6MonthAgo DATETIME; SET @6MonthAgo = DATEADD(MONTH,-6,@TodayDate);
DECLARE @3MonthAgo DATETIME; SET @3MonthAgo = DATEADD(MONTH,-3,@TodayDate);
DECLARE @2MonthAgo DATETIME; SET @2MonthAgo = DATEADD(MONTH,-2,@TodayDate);
DECLARE @CurDay SMALLINT; SET @CurDay = dbo.fnDayByDate(@TodayDate);

DECLARE @Today_Date_key INT;
SELECT @Today_Date_key = Date_key FROM dbo.DimDate WHERE FullDate = @TodayDate;

IF OBJECT_ID('tempdb..#NotebooksWithPaidPublishedVacs') IS NOT NULL DROP TABLE #NotebooksWithPaidPublishedVacs;
IF OBJECT_ID('tempdb..#NotebooksWithPaidPublicationsLeft') IS NOT NULL DROP TABLE #NotebooksWithPaidPublicationsLeft;
IF OBJECT_ID('tempdb..#NotebooksWithHotPublishedVacs') IS NOT NULL DROP TABLE #NotebooksWithHotPublishedVacs;
IF OBJECT_ID('tempdb..#NotebooksWithHotPublicationsLeft') IS NOT NULL DROP TABLE #NotebooksWithHotPublicationsLeft;
IF OBJECT_ID('tempdb..#NotebooksWithCVDB') IS NOT NULL DROP TABLE #NotebooksWithCVDB;
IF OBJECT_ID('tempdb..#NotebooksWithActivatedLogo') IS NOT NULL DROP TABLE #NotebooksWithActivatedLogo;
IF OBJECT_ID('tempdb..#NotebooksWithActivatedProfile') IS NOT NULL DROP TABLE #NotebooksWithActivatedProfile;
IF OBJECT_ID('tempdb..#PaymentStatuses') IS NOT NULL DROP TABLE #PaymentStatuses;

CREATE TABLE #NotebooksWithPaidPublishedVacs (NotebookID INT PRIMARY KEY);
INSERT INTO #NotebooksWithPaidPublishedVacs
SELECT DISTINCT NotebookID 
FROM 
 (SELECT VP.ID, VP.NotebookID
   , ROW_NUMBER() OVER(PARTITION BY VP.ID ORDER BY NCS.AddDate DESC) AS RowNum
   , COALESCE(RTP.TicketPaymentTypeID, TP.TicketPaymentTypeID) AS TicketPaymentTypeID
  FROM SRV16.RabotaUA2.dbo.VacancyPublished VP
   JOIN SRV16.RabotaUA2.dbo.NotebookCompany_Spent NCS ON VP.ID = NCS.VacancyID
   LEFT JOIN SRV16.RabotaUA2.dbo.RegionalTicketPayment RTP ON NCS.TicketPaymentID = RTP.ID AND NCS.RegionalPackageID IS NOT NULL
   LEFT JOIN SRV16.RabotaUA2.dbo.TicketPayment TP ON NCS.TicketPaymentID = TP.ID AND NCS.RegionalPackageID IS NULL
  WHERE SpendType <> 5) AS PublishedVacsTicketSpents
WHERE RowNum = 1 AND TicketPaymentTypeID NOT IN (5,6);

CREATE TABLE #NotebooksWithPaidPublicationsLeft (NotebookID INT PRIMARY KEY);

-- CTE с потраченными билетиками
WITH C AS
 (
SELECT TicketPaymentID, TicketType, RegionalPackageID, TicketAwayCount AS Quantity 
FROM SRV16.RabotaUA2.dbo.TicketAway WITH (NOLOCK)
WHERE TicketType IN (1,2,3)

UNION ALL

SELECT TicketPaymentID, SpendType, RegionalPackageID, SpendCount AS Quantity 
FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent WITH (NOLOCK)
WHERE RegionalPackageID IS NULL
 )
-- CTE с кол-вом билетиков по блокнотам
 , C_Notebooks_Tickets AS
 (
SELECT NotebookID, rtVacancyStandart, rtVacancyDesigned
 , (SELECT SUM(VacancyStandart) 
    FROM SRV16.RabotaUA2.dbo.TicketPayment TP WITH (NOLOCK)
	WHERE TP.NotebookId = NC.NotebookId AND TP.ExpiryDate >= @TodayDate AND TP.TicketPaymentTypeID NOT IN (5,6)) AS VacancyStandart_IN
 , (SELECT SUM(C.Quantity) 
	FROM C 
	 JOIN SRV16.RabotaUA2.dbo.TicketPayment TP  WITH (NOLOCK) ON C.TicketPaymentID = TP.ID
	WHERE TP.NotebookId = NC.NotebookId AND TP.ExpiryDate >= @TodayDate AND TP.TicketPaymentTypeID NOT IN (5,6)
	 AND TP.VacancyStandart > 0) AS VacancyStandart_OUT
 , (SELECT SUM(VacancyDesigned) 
    FROM SRV16.RabotaUA2.dbo.TicketPayment TP  WITH (NOLOCK)
	WHERE TP.NotebookId = NC.NotebookId AND TP.ExpiryDate >= @TodayDate AND TP.TicketPaymentTypeID NOT IN (5,6)) AS VacancyDesigned_IN
 , (SELECT SUM(C.Quantity) 
	FROM C 
	 JOIN SRV16.RabotaUA2.dbo.TicketPayment TP WITH (NOLOCK) ON C.TicketPaymentID = TP.ID
	WHERE TP.NotebookId = NC.NotebookId AND TP.ExpiryDate >= @TodayDate AND TP.TicketPaymentTypeID NOT IN (5,6)
	 AND TP.VacancyDesigned > 0) AS VacancyDesigned_OUT
 , ISNULL((SELECT SUM(TicketRestCount)
	FROM SRV16.RabotaUA2.dbo.NotebookRegionalTicket NRT WITH (NOLOCK)
		JOIN SRV16.RabotaUA2.dbo.RegionalTicketPayment RTP WITH (NOLOCK) ON NRT.PayId = RTP.Id
	WHERE NRT.NotebookId = NC.NotebookId 
	    AND NRT.PackageId = 18 AND RTP.TicketPaymentTypeID NOT IN (5,6)
		AND @CurDay BETWEEN NRT.DateStart AND NRT.DateValid 
		AND NRT.TicketRestCount > 0),0) AS calcVacancyBusiness
FROM SRV16.RabotaUA2.dbo.NotebookCompany NC WITH (NOLOCK)
WHERE NC.rtVacancyStandart > 0 
 OR NC.rtVacancyDesigned > 0 
 OR EXISTS (SELECT *
			FROM SRV16.RabotaUA2.dbo.NotebookRegionalTicket NRT WITH (NOLOCK)
			 JOIN SRV16.RabotaUA2.dbo.RegionalTicketPayment RTP WITH (NOLOCK) ON NRT.PayId = RTP.Id
			WHERE NRT.NotebookId = NC.NotebookId AND NRT.PackageId = 18 AND RTP.TicketPaymentTypeID NOT IN (5,6)
			 AND @CurDay BETWEEN NRT.DateStart AND NRT.DateValid 
			 AND NRT.TicketRestCount > 0)
 )

INSERT INTO #NotebooksWithPaidPublicationsLeft
SELECT NotebookID
FROM C_Notebooks_Tickets
WHERE (ISNULL(VacancyStandart_IN,0) - ISNULL(VacancyStandart_OUT,0)) > 0 OR (ISNULL(VacancyDesigned_IN,0) - ISNULL(VacancyDesigned_OUT,0)) > 0 OR calcVacancyBusiness > 0;

CREATE TABLE #NotebooksWithHotPublishedVacs (NotebookID INT PRIMARY KEY);
INSERT INTO #NotebooksWithHotPublishedVacs
SELECT DISTINCT NotebookID
FROM (SELECT VP.ID, VP.NotebookID
       , ROW_NUMBER() OVER(PARTITION BY VP.ID ORDER BY NCS.AddDate DESC) AS RowNum
	   , TP.TicketPaymentTypeID
	  FROM SRV16.RabotaUA2.dbo.VacancyPublished VP
	   JOIN SRV16.RabotaUA2.dbo.VacancyExtra VE ON VP.ID = VE.VacancyID
	   JOIN SRV16.RabotaUA2.dbo.NotebookCompany_Spent NCS ON VP.ID = NCS.VacancyID
	   JOIN SRV16.RabotaUA2.dbo.TicketPayment TP ON NCS.TicketPaymentID = TP.ID
	  WHERE SpendType = 5 AND @TodayDate BETWEEN VE.HotStartDate AND VE.HotEndDate) AS HotPublishedVacsTicketSpents
WHERE RowNum = 1 AND TicketPaymentTypeID NOT IN (5,6);

CREATE TABLE #NotebooksWithHotPublicationsLeft (NotebookID INT PRIMARY KEY);
INSERT INTO #NotebooksWithHotPublicationsLeft
SELECT NotebookID 
FROM SRV16.RabotaUA2.dbo.NotebookCompany NC
WHERE NC.rtVacancyHot > 0
 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.TicketPayment TP 
			 WHERE TP.NotebookId = NC.NotebookId 
			  AND TP.TicketPaymentTypeID NOT IN (5,6) AND TP.State = 10 AND TP.VacancyHot > 0
			  AND TP.ExpiryDate >= @TodayDate);

CREATE TABLE #NotebooksWithCVDB (NotebookID INT PRIMARY KEY)
INSERT INTO #NotebooksWithCVDB
SELECT DISTINCT NotebookId 
FROM SRV16.RabotaUA2.dbo.TemporalPayment
WHERE @TodayDate BETWEEN StartDate AND EndDate AND Price > 0;

CREATE TABLE #NotebooksWithActivatedLogo (NotebookID INT PRIMARY KEY)
INSERT INTO #NotebooksWithActivatedLogo
SELECT DISTINCT NotebookID
FROM SRV16.RabotaUA2.dbo.OrderDetail OD
 JOIN SRV16.RabotaUA2.dbo.Orders O ON OD.OrderID = O.ID
WHERE OD.ServiceID BETWEEN 27 AND 46
 AND @TodayDate BETWEEN OD.ActivationStartDate AND OD.ActivationEndDate;

CREATE TABLE #NotebooksWithActivatedProfile (NotebookID INT PRIMARY KEY)
INSERT INTO #NotebooksWithActivatedProfile
SELECT DISTINCT NotebookID
FROM SRV16.RabotaUA2.dbo.OrderDetail OD
 JOIN SRV16.RabotaUA2.dbo.Orders O ON OD.OrderID = O.ID
WHERE OD.ServiceID IN (25,26)
 AND @TodayDate BETWEEN OD.ActivationStartDate AND OD.ActivationEndDate


INSERT INTO dbo.FactCompanyStatuses (
   Company_key
 , Date_key
 , Rating
 , IsMegaChecked
 , IsPriority2013
 , HasPaidPublishedVacs
 , HasPaidPublicationsLeft
 , HasHotPublishedVacs
 , HasHotPublicationsLeft
 , HasCVDBAccess
 , HasActivatedLogo
 , HasActivatedProfile
 , MonthsFromRegDate
 , PublicationsNum
 , PublicationsNumLast6Months
 , PublicationsNumLast3Months
 , PublicationsNumLast2Months
 , MonthsNumLast6Months
 , MonthsNumLast3Months
 , MonthsNumLast2Months
 , VacancyNum
 , WorkVacancyNum
 , AvgLast3Month
 , IndexActivity
 , IndexAttraction
 , VacancyDiffGroup
 , UnqVacancyNum
 , UnqWorkVacancyNum
 , HasPaidServices)
SELECT
   DC.Company_key
 , @Today_Date_key
 , ISNULL(NC.Rating,0)
 , CASE WHEN N.NotebookStateId = 7 THEN 1 ELSE 0 END
 , ISNULL(NCE.Admin3_TrophyBrand_IsPriority2013,0)
 , CASE 
    WHEN EXISTS (SELECT * FROM #NotebooksWithPaidPublishedVacs WHERE NotebookID = NC.NotebookId) THEN 1
    ELSE 0
   END AS 'HasPaidPublishedVacs'
 , CASE 
    WHEN EXISTS (SELECT * FROM #NotebooksWithPaidPublicationsLeft WHERE NotebookID = NC.NotebookId) THEN 1
    ELSE 0
   END AS 'HasPaidPublicationsLeft'
 , CASE 
    WHEN EXISTS (SELECT * FROM #NotebooksWithHotPublishedVacs WHERE NotebookID = NC.NotebookId) THEN 1
    ELSE 0
   END AS 'HasHotPublishedVacs'
 , CASE 
    WHEN EXISTS (SELECT * FROM #NotebooksWithHotPublicationsLeft WHERE NotebookID = NC.NotebookId) THEN 1
    ELSE 0
   END AS 'HasHotPublicationsLeft'
 , CASE
    WHEN EXISTS (SELECT * FROM #NotebooksWithCVDB WHERE NotebookID = NC.NotebookID) THEN 1
    ELSE 0
   END AS 'HasCVDBAccess'
 , CASE
    WHEN EXISTS (SELECT * FROM #NotebooksWithActivatedLogo WHERE NotebookID = NC.NotebookID) THEN 1 
    ELSE 0
   END AS 'HasActivatedLogo'
 , CASE
    WHEN EXISTS (SELECT * FROM #NotebooksWithActivatedProfile WHERE NotebookID = NC.NotebookID) THEN 1
    ELSE 0
   END AS 'HasActivatedProfile'
 , (SELECT DATEDIFF(MONTH, NC.AddDate, @TodayDate))
 , (SELECT COUNT(DISTINCT VPH.VacancyId) 
	FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent VPH 
     JOIN SRV16.RabotaUA2.dbo.VacancyExtra VE ON VPH.VacancyId = VE.VacancyId
	 JOIN SRV16.RabotaUA2.dbo.Vacancy V ON VPH.VacancyId = V.Id
    WHERE VPH.SpendType <> 5 
	 AND VE.IsModerated = 1 AND VE.IsModeratedRubric = 1 
	 AND V.NotebookId = NC.NotebookId AND VPH.AddDate BETWEEN @Yesterday AND @TodayDate)
 , (SELECT COUNT(VPH.VacancyId) 
	FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent VPH 
     JOIN SRV16.RabotaUA2.dbo.VacancyExtra VE ON VPH.VacancyId = VE.VacancyId
	 JOIN SRV16.RabotaUA2.dbo.Vacancy V ON VPH.VacancyId = V.Id
    WHERE VPH.SpendType <> 5
	 AND VE.IsModerated = 1 AND VE.IsModeratedRubric = 1 
	 AND V.NotebookId = NC.NotebookId AND VPH.AddDate >= @6MonthAgo)
 , (SELECT COUNT(VPH.VacancyId) 
	FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent VPH 
     JOIN SRV16.RabotaUA2.dbo.VacancyExtra VE ON VPH.VacancyId = VE.VacancyId
	 JOIN SRV16.RabotaUA2.dbo.Vacancy V ON VPH.VacancyId = V.Id
    WHERE VPH.SpendType <> 5
	 AND VE.IsModerated = 1 AND VE.IsModeratedRubric = 1 
	 AND V.NotebookId = NC.NotebookId AND VPH.AddDate >= @3MonthAgo)
 , (SELECT COUNT(VPH.VacancyId) 
	FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent VPH 
     JOIN SRV16.RabotaUA2.dbo.VacancyExtra VE ON VPH.VacancyId = VE.VacancyId
	 JOIN SRV16.RabotaUA2.dbo.Vacancy V ON VPH.VacancyId = V.Id
    WHERE VPH.SpendType <> 5
	 AND VE.IsModerated = 1 AND VE.IsModeratedRubric = 1 
	 AND V.NotebookId = NC.NotebookId AND VPH.AddDate >= @2MonthAgo)
 , (SELECT COUNT(DISTINCT DATEPART(MONTH, VPH.AddDate)) 
	FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent VPH 
     JOIN SRV16.RabotaUA2.dbo.VacancyExtra VE ON VPH.VacancyId = VE.VacancyId
	 JOIN SRV16.RabotaUA2.dbo.Vacancy V ON VPH.VacancyId = V.Id
    WHERE VPH.SpendType <> 5
	 AND VE.IsModerated = 1 AND VE.IsModeratedRubric = 1 
	 AND V.NotebookId = NC.NotebookId AND VPH.AddDate >= @6MonthAgo)
 , (SELECT COUNT(DISTINCT DATEPART(MONTH, VPH.AddDate)) 
	FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent VPH 
     JOIN SRV16.RabotaUA2.dbo.VacancyExtra VE ON VPH.VacancyId = VE.VacancyId
	 JOIN SRV16.RabotaUA2.dbo.Vacancy V ON VPH.VacancyId = V.Id
    WHERE VPH.SpendType <> 5 
	 AND VE.IsModerated = 1 AND VE.IsModeratedRubric = 1 
	 AND V.NotebookId = NC.NotebookId AND VPH.AddDate >= @3MonthAgo)
 , (SELECT COUNT(DISTINCT DATEPART(MONTH, VPH.AddDate)) 
	FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent VPH 
     JOIN SRV16.RabotaUA2.dbo.VacancyExtra VE ON VPH.VacancyId = VE.VacancyId
	 JOIN SRV16.RabotaUA2.dbo.Vacancy V ON VPH.VacancyId = V.Id
    WHERE VPH.SpendType <> 5 
	 AND VE.IsModerated = 1 AND VE.IsModeratedRubric = 1 
	 AND V.NotebookId = NC.NotebookId AND VPH.AddDate >= @2MonthAgo)
 , DC.VacancyNum
 , DC.WorkVacancyNum
 , DC.AvgLast3Month
 , DC.IndexActivity
 , DC.IndexAttraction
 , DC.VacancyDiffGroup
 , DC.UnqVacancyNum
 , DC.UnqWorkVacancyNum
 , CASE 
    WHEN EXISTS (SELECT * FROM #NotebooksWithPaidPublishedVacs WHERE NotebookID = NC.NotebookId) THEN 1
	WHEN EXISTS (SELECT * FROM #NotebooksWithPaidPublicationsLeft WHERE NotebookID = NC.NotebookId) THEN 1
	WHEN EXISTS (SELECT * FROM #NotebooksWithHotPublishedVacs WHERE NotebookID = NC.NotebookId) THEN 1
	WHEN EXISTS (SELECT * FROM #NotebooksWithHotPublicationsLeft WHERE NotebookID = NC.NotebookId) THEN 1
	WHEN EXISTS (SELECT * FROM #NotebooksWithCVDB WHERE NotebookID = NC.NotebookID) THEN 1
	WHEN EXISTS (SELECT * FROM #NotebooksWithActivatedLogo WHERE NotebookID = NC.NotebookID) THEN 1
	WHEN EXISTS (SELECT * FROM #NotebooksWithActivatedProfile WHERE NotebookID = NC.NotebookID) THEN 1
	ELSE 0 END
FROM SRV16.RabotaUA2.dbo.NotebookCompany NC
 JOIN SRV16.RabotaUA2.dbo.Notebook N ON NC.NotebookId = N.Id
 JOIN SRV16.RabotaUA2.dbo.NotebookCompanyExtra NCE ON NC.NotebookId = NCE.NotebookId
 JOIN Reporting.dbo.DimCompany DC ON NC.NotebookId = DC.NotebookId;

-- обновление PaymentStatus'ов для каждой компании
SELECT Company_key, Date_key,  HasPaidServices, PaymentStatusKey
 , ISNULL((SELECT TOP 1 HasPaidServices FROM FactCompanyStatuses WHERE Company_key = FCS.Company_key AND Date_key < FCS.Date_key ORDER BY Date_key DESC),0) AS HasPaidServicesYesterday
 , ISNULL((SELECT DISTINCT 1 FROM FactCompanyStatuses WHERE Company_key = FCS.Company_key AND Date_key < FCS.Date_key AND HasPaidServices = 1),0) AS HasPaidServicesBefore
INTO #PaymentStatuses
FROM FactCompanyStatuses FCS
WHERE Date_key = @Today_Date_key

UPDATE dbo.FactCompanyStatuses
SET PaymentStatusKey 
					 = CASE
						WHEN PS.HasPaidServices = 1 AND PS.HasPaidServicesYesterday = 0 AND PS.HasPaidServicesBefore = 0 THEN 1
						WHEN PS.HasPaidServices = 1 AND PS.HasPaidServicesYesterday = 0 AND PS.HasPaidServicesBefore = 1 THEN 2
						WHEN PS.HasPaidServices = 0 AND PS.HasPaidServicesYesterday = 1 THEN 3
					   END
FROM #PaymentStatuses PS
 JOIN FactCompanyStatuses FCS ON PS.Company_key = FCS.Company_key AND PS.Date_key = FCS.Date_key;


DROP TABLE #NotebooksWithPaidPublishedVacs;
DROP TABLE #NotebooksWithPaidPublicationsLeft;
DROP TABLE #NotebooksWithHotPublishedVacs;
DROP TABLE #NotebooksWithHotPublicationsLeft;
DROP TABLE #NotebooksWithCVDB;
DROP TABLE #NotebooksWithActivatedLogo;
DROP TABLE #NotebooksWithActivatedProfile;
DROP TABLE #PaymentStatuses;