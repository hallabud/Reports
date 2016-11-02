
CREATE PROCEDURE [dbo].[usp_ssrs_ReportAverageViewsAndFreePubs]
AS

---- разрезы:
---- 1. разместили платную вакансию хоть раз
---- 2. потратили хотя бы раз 3 бесплатные базовые публикации (для МП) или 1 (для П)
---- 3. Мегапроверенные юрлица (премиум)
---- 4. Опубликовали хотя бы 1 вакансию или в месяц регистрации, или в следующем месяце
---- 5. Хотя бы 1 раз покупали доступ к CVDB
---- 6. (3)Мегапроверенные юрлица (не премиум)
--
IF OBJECT_ID('tempdb..#HasPaidVacancy','U') IS NOT NULL DROP TABLE #HasPaidVacancy;
IF OBJECT_ID('tempdb..#HasFullFreePubs','U') IS NOT NULL DROP TABLE #HasFullFreePubs;
IF OBJECT_ID('tempdb..#IsMegaLegals','U') IS NOT NULL DROP TABLE #IsMegaLegals;
IF OBJECT_ID('tempdb..#HasFirstPubInFirst2Months','U') IS NOT NULL DROP TABLE #HasFirstPubInFirst2Months;
IF OBJECT_ID('tempdb..#HasCvdbAccess','U') IS NOT NULL DROP TABLE #HasCvdbAccess;
IF OBJECT_ID('tempdb..#IsMegaLegalsNotPremium','U') IS NOT NULL DROP TABLE #IsMegaLegalsNotPremium;
IF OBJECT_ID('tempdb..#ContactViews','U') IS NOT NULL DROP TABLE #ContactViews;
IF OBJECT_ID('tempdb..#FreePubs','U') IS NOT NULL DROP TABLE #FreePubs;
IF OBJECT_ID('tempdb..#PaidPubs','U') IS NOT NULL DROP TABLE #PaidPubs;

DECLARE @TodayDate DATETIME;
DECLARE @ResultSet TABLE 
 (ResultGroup VARCHAR(200),
  NotebookCount INT,
  ContacViewsCount DECIMAL(10,2),
  FreePubs DECIMAL(10,2),
  PaidPubs DECIMAL(10,2));

SET @TodayDate = dbo.fnGetDatePart(GETDATE());

-- 1. Разместили платную вакансию хоть раз
SELECT DISTINCT
   NCS.NotebookId
INTO #HasPaidVacancy
FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent NCS
 LEFT JOIN SRV16.RabotaUA2.dbo.RegionalTicketPayment RTP 
  ON NCS.TicketPaymentID = RTP.Id
WHERE NCS.SpendType <> 4 
      OR (NCS.SpendType = 4 
	      AND RTP.TicketPaymentTypeID < 5
	      AND RTP.State = 10
          AND RTP.NotebookPaymentStateId = 1)

-- 2. Хотя бы раз потратили все месячные бесплатные публикации, и не публиковали платные
SELECT DISTINCT
   NCS.NotebookId
INTO #HasFullFreePubs
FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent NCS
 JOIN SRV16.RabotaUA2.dbo.Notebook N ON NCS.NotebookId = N.Id
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC ON NC.NotebookId = N.Id
 JOIN SRV16.RabotaUA2.dbo.RegionalTicketPayment RTP ON NCS.TicketPaymentID = RTP.Id
 JOIN Reporting.dbo.DimDate DD ON dbo.fnGetDatePart(NCS.AddDate) = DD.FullDate
WHERE 
 N.NotebookStateId IN (5,7)
 AND NCS.SpendType = 4 
 AND NCS.RegionalPackageID = 18 
 AND RTP.TicketPaymentTypeID = 6
 AND NOT EXISTS (SELECT * FROM #HasPaidVacancy WHERE NotebookId = NCS.NotebookId)
GROUP BY 
   NCS.NotebookId
 , N.NotebookStateId
 , CAST(DD.YearNum AS VARCHAR) + CAST(DD.MonthNum AS VARCHAR)
HAVING COUNT(*) = CASE N.NotebookStateId WHEN 7 THEN 3 ELSE 1 END

-- 3. Мегапроверенные юрлица (премиум)
SELECT
   NC.NotebookId
INTO #IsMegaLegals
FROM SRV16.RabotaUA2.dbo.NotebookCompany NC
 JOIN SRV16.RabotaUA2.dbo.Notebook N ON NC.NotebookId = N.Id
WHERE NC.IsLegalPerson = 1 AND N.NotebookStateId = 7 AND NC.IsPremium = 1

-- 4. Опубликовали хотя бы 1 вакансию в месяц регистрации и хотя бы 1 в любом следующем
SELECT DISTINCT
   NCS.NotebookId
INTO #HasFirstPubInFirst2Months
FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent NCS
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC ON NCS.NotebookId = NC.NotebookId
WHERE DATEDIFF(MONTH,NC.AddDate,NCS.AddDate) < 1
 AND EXISTS (SELECT * 
			 FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent NCS2
			  JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC2 ON NCS2.NotebookId = NC2.NotebookId
			 WHERE NCS2.NotebookId = NCS.NotebookId
              AND DATEDIFF(MONTH,NC2.AddDate,NCS2.AddDate) >= 1)
GROUP BY NCS.NotebookId

-- 5. Хотя бы 1 раз покупали доступ к CVDB
SELECT DISTINCT
   TP.NotebookID
INTO #HasCvdbAccess
FROM SRV16.RabotaUA2.dbo.TemporalPayment TP
WHERE TP.NotebookPaymentStateId = 1

-- 6. Мегапроверенные юрлица (не премиум)
SELECT
   NC.NotebookId
INTO #IsMegaLegalsNotPremium
FROM SRV16.RabotaUA2.dbo.NotebookCompany NC
 JOIN SRV16.RabotaUA2.dbo.Notebook N ON NC.NotebookId = N.Id
WHERE NC.IsLegalPerson = 1 AND N.NotebookStateId = 7 AND NC.IsPremium = 0 

-- Кол-во просмотренных контактов на компанию за последние полгода
SELECT EmployerNotebookId AS NotebookId, COUNT(*) AS ContactViewsCount
INTO #ContactViews
FROM SRV16.RabotaUA2.dbo.DailyViewedResume
WHERE ViewDate >= DATEADD(MONTH,-6,@TodayDate)
GROUP BY EmployerNotebookId

-- Кол-во публикаций бесплатных вакансий
SELECT NCS.NotebookId, COUNT(*) AS FreePubs
INTO #FreePubs
FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent NCS
 JOIN SRV16.RabotaUA2.dbo.RegionalTicketPayment RTP ON NCS.TicketPaymentID = RTP.Id
WHERE NCS.AddDate >= DATEADD(MONTH,-6,@TodayDate)
 AND NCS.SpendType = 4 
 AND NCS.RegionalPackageID = 18 
 AND RTP.TicketPaymentTypeID = 6 
GROUP BY NCS.NotebookId;

-- Кол-во публикаций платных вакансий
SELECT NCS.NotebookId, COUNT(*) AS PaidPubs
INTO #PaidPubs
FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent NCS
 LEFT JOIN SRV16.RabotaUA2.dbo.RegionalTicketPayment RTP ON NCS.TicketPaymentID = RTP.Id
WHERE NCS.AddDate >= DATEADD(MONTH,-6,@TodayDate)
 AND NCS.SpendType <> 4 
      OR (NCS.SpendType = 4 
	      AND RTP.TicketPaymentTypeID < 5
	      AND RTP.State = 10
          AND RTP.NotebookPaymentStateId = 1)
GROUP BY NCS.NotebookId;


INSERT INTO @ResultSet
SELECT 
   '1.Разместили платную вакансию хоть раз за все время' AS ResultGroup
 , COUNT(HPV.NotebookId) AS NotebookCount
 , AVG(ISNULL(CAST(ContactViewsCount AS DECIMAL(10,2)),0)) AS ContactViewsCount
 , AVG(ISNULL(CAST(FreePubs AS DECIMAL(10,2)),0)) AS FreePubs
 , AVG(ISNULL(CAST(PaidPubs AS DECIMAL(10,2)),0)) AS PaidPubs
FROM #HasPaidVacancy HPV
 LEFT JOIN #ContactViews CV ON HPV.NotebookId = CV.NotebookId
 LEFT JOIN #FreePubs FP ON HPV.NotebookId = FP.NotebookId
 LEFT JOIN #PaidPubs PP ON HPV.NotebookId = PP.NotebookId
UNION ALL
SELECT 
   '2.Потратили хоть раз за все время в одном месяце 3(1) бесплатные базовые публикации и не публиковали платные' AS ResultGroup
 , COUNT(HFFP.NotebookId) AS NotebookCount
 , AVG(ISNULL(CAST(ContactViewsCount AS DECIMAL(10,2)),0)) AS ContactViewsCount
 , AVG(ISNULL(CAST(FreePubs AS DECIMAL(10,2)),0)) AS FreePubs
 , AVG(ISNULL(CAST(PaidPubs AS DECIMAL(10,2)),0)) AS PaidPubs
FROM #HasFullFreePubs HFFP
 LEFT JOIN #ContactViews CV ON HFFP.NotebookId = CV.NotebookId
 LEFT JOIN #FreePubs FP ON HFFP.NotebookId = FP.NotebookId
 LEFT JOIN #PaidPubs PP ON HFFP.NotebookId = PP.NotebookId
UNION ALL
SELECT 
   '3.Мегапроверенные юрлица (премиум)' AS ResultGroup
 , COUNT(IML.NotebookId) AS NotebookCount
 , AVG(ISNULL(CAST(ContactViewsCount AS DECIMAL(10,2)),0)) AS ContactViewsCount
 , AVG(ISNULL(CAST(FreePubs AS DECIMAL(10,2)),0)) AS FreePubs
 , AVG(ISNULL(CAST(PaidPubs AS DECIMAL(10,2)),0)) AS PaidPubs
FROM #IsMegaLegals IML
 LEFT JOIN #ContactViews CV ON IML.NotebookId = CV.NotebookId
 LEFT JOIN #FreePubs FP ON IML.NotebookId = FP.NotebookId
 LEFT JOIN #PaidPubs PP ON IML.NotebookId = PP.NotebookId
UNION ALL
SELECT 
   '4.Компании, которые опубликовали вакансию в календарном месяце своей регистрации И в любом следующем' AS ResultGroup
 , COUNT(HFP2M.NotebookId) AS NotebookCount
 , AVG(ISNULL(CAST(ContactViewsCount AS DECIMAL(10,2)),0)) AS ContactViewsCount
 , AVG(ISNULL(CAST(FreePubs AS DECIMAL(10,2)),0)) AS FreePubs
 , AVG(ISNULL(CAST(PaidPubs AS DECIMAL(10,2)),0)) AS PaidPubs
FROM #HasFirstPubInFirst2Months HFP2M
 LEFT JOIN #ContactViews CV ON HFP2M.NotebookId = CV.NotebookId
 LEFT JOIN #FreePubs FP ON HFP2M.NotebookId = FP.NotebookId
 LEFT JOIN #PaidPubs PP ON HFP2M.NotebookId = PP.NotebookId
UNION ALL
SELECT
   '5.Компании, которые хотя бы 1 раз покупали доступ к CVDB'
 , COUNT(HCVDB.NotebookId) AS NotebookCount
 , AVG(ISNULL(CAST(ContactViewsCount AS DECIMAL(10,2)),0)) AS ContactViewsCount
 , AVG(ISNULL(CAST(FreePubs AS DECIMAL(10,2)),0)) AS FreePubs
 , AVG(ISNULL(CAST(PaidPubs AS DECIMAL(10,2)),0)) AS PaidPubs
FROM #HasCvdbAccess HCVDB
 LEFT JOIN #ContactViews CV ON HCVDB.NotebookId = CV.NotebookId
 LEFT JOIN #FreePubs FP ON HCVDB.NotebookId = FP.NotebookId
 LEFT JOIN #PaidPubs PP ON HCVDB.NotebookId = PP.NotebookId
UNION ALL
SELECT 
   '3.Мегапроверенные юрлица (не премиум)'
 , COUNT(IMLNP.NotebookId) AS NotebookCount
 , AVG(ISNULL(CAST(ContactViewsCount AS DECIMAL(10,2)),0)) AS ContactViewsCount
 , AVG(ISNULL(CAST(FreePubs AS DECIMAL(10,2)),0)) AS FreePubs
 , AVG(ISNULL(CAST(PaidPubs AS DECIMAL(10,2)),0)) AS PaidPubs
FROM #IsMegaLegalsNotPremium IMLNP
 LEFT JOIN #ContactViews CV ON IMLNP.NotebookId = CV.NotebookId
 LEFT JOIN #FreePubs FP ON IMLNP.NotebookId = FP.NotebookId
 LEFT JOIN #PaidPubs PP ON IMLNP.NotebookId = PP.NotebookId  ;

SELECT * FROM @ResultSet;

DROP TABLE #HasPaidVacancy;
DROP TABLE #HasFullFreePubs;
DROP TABLE #IsMegaLegals;
DROP TABLE #HasFirstPubInFirst2Months;
DROP TABLE #HasCvdbAccess;
DROP TABLE #IsMegaLegalsNotPremium;
DROP TABLE #ContactViews;
DROP TABLE #FreePubs;
DROP TABLE #PaidPubs;