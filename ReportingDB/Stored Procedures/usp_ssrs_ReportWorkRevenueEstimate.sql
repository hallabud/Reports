
CREATE PROCEDURE [dbo].[usp_ssrs_ReportWorkRevenueEstimate]
AS

DECLARE @FirstDate DATE = DATEADD(YEAR, -1, DATEADD(DAY, 1 - DATEPART(DAY, GETDATE()), CAST(GETDATE() AS DATE)));

IF OBJECT_ID('tempdb..#RevenuePubs_Grouped','U') IS NOT NULL DROP TABLE #RevenuePubs_Grouped;
IF OBJECT_ID('tempdb..#RevenueHot_Grouped','U') IS NOT NULL DROP TABLE #RevenueHot_Grouped;
IF OBJECT_ID('tempdb..#RevenueVIP_Grouped','U') IS NOT NULL DROP TABLE #RevenueVIP_Grouped;
IF OBJECT_ID('tempdb..#RevenueLogoMain_Grouped','U') IS NOT NULL DROP TABLE #RevenueLogoMain_Grouped;
IF OBJECT_ID('tempdb..#RevenueBusiness_Grouped','U') IS NOT NULL DROP TABLE #RevenueBusiness_Grouped; 

-- Расчет дохода от публикаций
-- Кол-во опубликованных вакансий в последний день месяца - (минус) 1 бесплатная * цена, указанная в ТЗ
SELECT FullDate, YearNum, MonthNum, MonthNameRus
 , SUM(RevenuePubs) AS RevenuePubsSum
 , COUNT(*) AS CompaniesNum
INTO #RevenuePubs_Grouped
FROM
(
SELECT FSCI.SpiderCompanyID, D.FullDate, D.YearNum, D.MonthNum, D.MonthNameRus
 , (VacancyCount - CASE WHEN IsBusiness = 1 THEN 3 ELSE 1 END) *  
	  (CASE  
	   WHEN (VacancyCount - CASE WHEN IsBusiness = 1 THEN 3 ELSE 1 END) * 5 BETWEEN 1 AND 4 THEN 199.
	   WHEN (VacancyCount - CASE WHEN IsBusiness = 1 THEN 3 ELSE 1 END) * 5 BETWEEN 5 AND 9 THEN 177.
	   WHEN (VacancyCount - CASE WHEN IsBusiness = 1 THEN 3 ELSE 1 END) * 5 BETWEEN 10 AND 24 THEN 159.
	   WHEN (VacancyCount - CASE WHEN IsBusiness = 1 THEN 3 ELSE 1 END) * 5 BETWEEN 25 AND 49 THEN 139.
	   WHEN (VacancyCount - CASE WHEN IsBusiness = 1 THEN 3 ELSE 1 END) * 5 BETWEEN 50 AND 99 THEN 119.
	   WHEN (VacancyCount - CASE WHEN IsBusiness = 1 THEN 3 ELSE 1 END) * 5 >= 100 THEN 99.
	   ELSE 0 END) AS RevenuePubs
FROM dbo.FactSpiderCompanyIndexes FSCI
 JOIN dbo.DimSpiderCompany DSC ON FSCI.SpiderCompanyID = DSC.SpiderCompanyID
 JOIN dbo.DimDate D ON FSCI.Date_key = D.Date_key
WHERE D.FullDate >= @FirstDate
 AND D.IsLastDayOfMonth = 1 AND FSCI.IsPaidByTickets = 1 AND DSC.SpiderSource_key = 1
) Pubs
GROUP BY FullDate, YearNum, MonthNum, MonthNameRus;

-- Расчет дохода от горячих
-- Сумма значений в поле HotVacancyNum за все даты еженедельного забора данных в рамках определенного месяца
SELECT LastMonthDate AS FullDate, YearNum, MonthNum, MonthNameRus
 , SUM(RevenueHot) AS RevenueHotSum
 , COUNT(*) AS CompaniesNum
INTO #RevenueHot_Grouped
FROM 
(
SELECT FSCI.SpiderCompanyID, D.LastMonthDate, D.YearNum, D.MonthNum, D.MonthNameRus
 , SUM(FSCI.HotVacancyCount) *
   (CASE 
     WHEN SUM(FSCI.HotVacancyCount) * 3 BETWEEN 1 AND 4 THEN 749.
	 WHEN SUM(FSCI.HotVacancyCount) * 3 BETWEEN 5 AND 9 THEN 648.
	 WHEN SUM(FSCI.HotVacancyCount) * 3 BETWEEN 10 AND 24 THEN 599.
	 WHEN SUM(FSCI.HotVacancyCount) * 3 BETWEEN 25 AND 49 THEN 524.
	 WHEN SUM(FSCI.HotVacancyCount) * 3 >= 50 THEN 449.
	 ELSE 0 END) AS RevenueHot
FROM dbo.FactSpiderCompanyIndexes FSCI
 JOIN dbo.DimSpiderCompany DSC ON FSCI.SpiderCompanyID = DSC.SpiderCompanyID
 JOIN dbo.DimDate D ON FSCI.Date_key = D.Date_key
WHERE D.FullDate >= @FirstDate
 AND D.WeekDayNum = 7 AND FSCI.HotVacancyCount > 0 AND DSC.SpiderSource_key = 1
GROUP BY FSCI.SpiderCompanyID, D.LastMonthDate, D.YearNum, D.MonthNum, D.MonthNameRus
) Hots
GROUP BY LastMonthDate, YearNum, MonthNum, MonthNameRus;

-- Расчет дохода от услуги VIP
-- Считаем по полю IsHasLogo по состоянию на последний день месяца
SELECT FullDate, YearNum, MonthNum, MonthNameRus
 , SUM(RevenueVIP) AS RevenueVIPSum
 , COUNT(*) AS CompaniesNum
INTO #RevenueVIP_Grouped
FROM
(
SELECT FSCI.SpiderCompanyID, D.FullDate, D.YearNum, D.MonthNum, D.MonthNameRus
 , 1625. AS RevenueVIP
FROM dbo.FactSpiderCompanyIndexes FSCI
 JOIN dbo.DimSpiderCompany DSC ON FSCI.SpiderCompanyID = DSC.SpiderCompanyID
 JOIN dbo.DimDate D ON FSCI.Date_key = D.Date_key
WHERE D.FullDate >= @FirstDate
 AND D.IsLastDayOfMonth = 1 AND FSCI.IsHasLogo = 1 AND DSC.SpiderSource_key = 1
) VIP
GROUP BY FullDate, YearNum, MonthNum, MonthNameRus;

-- Расчет дохода от услуги "Лого на главной"
-- Считаем по полю IsHasLogo_OnMain по состоянию на последний день месяца
SELECT FullDate, YearNum, MonthNum, MonthNameRus
 , SUM(RevenueLogoMain) AS RevenueLogoMainSum
 , COUNT(*) AS CompaniesNum
INTO #RevenueLogoMain_Grouped
FROM
(
SELECT FSCI.SpiderCompanyID, D.FullDate, D.YearNum, D.MonthNum, D.MonthNameRus
 , 3835. AS RevenueLogoMain
FROM dbo.FactSpiderCompanyIndexes FSCI
 JOIN dbo.DimSpiderCompany DSC ON FSCI.SpiderCompanyID = DSC.SpiderCompanyID
 JOIN dbo.DimDate D ON FSCI.Date_key = D.Date_key
WHERE D.FullDate >= @FirstDate
 AND D.IsLastDayOfMonth = 1 AND FSCI.IsHasLogo_OnMain = 1 AND DSC.SpiderSource_key = 1
) LogoMain
GROUP BY FullDate, YearNum, MonthNum, MonthNameRus;

-- Расчет дохода от услуги "Бизнес-размещение"
-- Считаем по полю IsBusiness по состоянию на последний день месяца
SELECT FullDate, YearNum, MonthNum, MonthNameRus
 , SUM(RevenueBusiness) AS RevenueBusinessSum
 , COUNT(*) AS CompaniesNum
INTO #RevenueBusiness_Grouped
FROM
(
SELECT FSCI.SpiderCompanyID, D.FullDate, D.YearNum, D.MonthNum, D.MonthNameRus
 , 83. AS RevenueBusiness
FROM dbo.FactSpiderCompanyIndexes FSCI
 JOIN dbo.DimSpiderCompany DSC ON FSCI.SpiderCompanyID = DSC.SpiderCompanyID
 JOIN dbo.DimDate D ON FSCI.Date_key = D.Date_key
WHERE D.FullDate >= @FirstDate
 AND D.IsLastDayOfMonth = 1 AND FSCI.IsBusiness = 1 AND DSC.SpiderSource_key = 1
) Business
GROUP BY FullDate, YearNum, MonthNum, MonthNameRus;


-- итоговая таблица
SELECT P.FullDate, P.YearNum, P.MonthNum, P.MonthNameRus
 , P.RevenuePubsSum
 , P.CompaniesNum * 0.15 * 2083. AS RevenueCVDB
 , H.RevenueHotSum
 , V.RevenueVIPSum
 , LM.RevenueLogoMainSum AS RevenueLogo
 , B.RevenueBusinessSum AS RevenueBusiness
FROM #RevenuePubs_Grouped P
 JOIN #RevenueHot_Grouped H ON P.FullDate = H.FullDate
 LEFT JOIN #RevenueVIP_Grouped V ON P.FullDate = V.FullDate
 LEFT JOIN #RevenueLogoMain_Grouped LM ON P.FullDate = LM.FullDate
 LEFT JOIN #RevenueBusiness_Grouped B ON P.FullDate = B.FullDate
ORDER BY FullDate;

DROP TABLE #RevenuePubs_Grouped;
DROP TABLE #RevenueHot_Grouped;
DROP TABLE #RevenueVIP_Grouped;
DROP TABLE #RevenueLogoMain_Grouped;
DROP TABLE #RevenueBusiness_Grouped