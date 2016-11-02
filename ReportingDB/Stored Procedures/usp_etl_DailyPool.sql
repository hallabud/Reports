
CREATE PROCEDURE [dbo].[usp_etl_DailyPool]

AS

IF OBJECT_ID('tempdb..#C') IS NOT NULL DROP TABLE #C;

DECLARE @PoolDate DATETIME;
DECLARE @PoolDay INT;

SELECT @PoolDate = MAX(dbo.fnGetDatePart(SubscriptionDate)) FROM Analytics.dbo.VacancySubscriptionActual;
SET @PoolDay = Analytics.dbo.fnDayByDate(@PoolDate);

SELECT SG.SynonymousID, SG.Name AS TagGroup, C.Id AS CityID, C.Name AS CityName
INTO #C
FROM Analytics.dbo.SynonymGroup SG WITH (NOLOCK)
 CROSS JOIN Analytics.dbo.City C WITH (NOLOCK)
WHERE C.Name IN ('Киев','Харьков','Днепропетровск','Одесса');

INSERT INTO Reporting.dbo.AggrDailyPool
SELECT
   @PoolDate 
 , SynonymousID
 , CityID
 , (SELECT COUNT(*)
    FROM Analytics.dbo.VacancySubscriptionActual VSA WITH (NOLOCK)
	WHERE CHARINDEX(',' + CAST(C.SynonymousID AS VARCHAR) + ',', ',' + VSA.SynonymousIDs + ',') > 0
	 AND CHARINDEX(',' + CAST(C.CityID AS VARCHAR) + ',', ',' + VSA.CityIDs + ',') > 0) AS VacancyCount
 , (SELECT COUNT(*)
    FROM Analytics.dbo.VacancySubscriptionActual VSA WITH (NOLOCK)
	WHERE CHARINDEX(',' + CAST(C.SynonymousID AS VARCHAR) + ',', ',' + VSA.SynonymousIDs + ',') > 0
	 AND CHARINDEX(',' + CAST(C.CityID AS VARCHAR) + ',', ',' + VSA.CityIDs + ',') > 0
	 AND VSA.IsNewForSubscription = 1) AS VacancyCount_New
 , (SELECT COUNT(*)
    FROM Analytics.dbo.VacancySubscriptionActual VSA WITH (NOLOCK)
	WHERE CHARINDEX(',' + CAST(C.SynonymousID AS VARCHAR) + ',', ',' + VSA.SynonymousIDs + ',') > 0
	 AND CHARINDEX(',' + CAST(C.CityID AS VARCHAR) + ',', ',' + VSA.CityIDs + ',') > 0
	 AND VSA.IsNewForSubscription = 0) AS VacancyCount_Upd
 , ISNULL(
   (SELECT SUM(Detail)
    FROM Analytics.dbo.VacancySubscriptionActual VSA WITH (NOLOCK)
	 JOIN SRV16.RabotaUA2.dbo.MegaVIPVacancyStatistic MVVS WITH (NOLOCK) ON VSA.VacancyID = MVVS.VacancyId
	WHERE CHARINDEX(',' + CAST(C.SynonymousID AS VARCHAR) + ',', ',' + VSA.SynonymousIDs + ',') > 0
	 AND CHARINDEX(',' + CAST(C.CityID AS VARCHAR) + ',', ',' + VSA.CityIDs + ',') > 0
	 AND MVVS.Day = @PoolDay + 1
	 AND VSA.IsNewForSubscription = 1),0) AS VacancyViews_New
 , ISNULL(
   (SELECT SUM(Detail)
    FROM Analytics.dbo.VacancySubscriptionActual VSA WITH (NOLOCK)
	 JOIN SRV16.RabotaUA2.dbo.MegaVIPVacancyStatistic MVVS WITH (NOLOCK) ON VSA.VacancyID = MVVS.VacancyId
	WHERE CHARINDEX(',' + CAST(C.SynonymousID AS VARCHAR) + ',', ',' + VSA.SynonymousIDs + ',') > 0
	 AND CHARINDEX(',' + CAST(C.CityID AS VARCHAR) + ',', ',' + VSA.CityIDs + ',') > 0
	 AND MVVS.Day = @PoolDay + 1
	 AND VSA.IsNewForSubscription = 0),0) AS VacancyViews_Upd
 , (SELECT COUNT(*)
    FROM Analytics.dbo.VacancySubscriptionActual VSA WITH (NOLOCK)
	 JOIN Analytics.dbo.VacancyApplyToVacancy VATV WITH (NOLOCK) ON VSA.VacancyID = VATV.VacancyId
	WHERE CHARINDEX(',' + CAST(C.SynonymousID AS VARCHAR) + ',', ',' + VSA.SynonymousIDs + ',') > 0
	 AND CHARINDEX(',' + CAST(C.CityID AS VARCHAR) + ',', ',' + VSA.CityIDs + ',') > 0
	 AND VSA.IsNewForSubscription = 1
	 AND VATV.AddDate BETWEEN @PoolDate + 1 AND @PoolDate + 2)
	+
	(SELECT COUNT(*)
    FROM Analytics.dbo.VacancySubscriptionActual VSA WITH (NOLOCK)
	 JOIN Analytics.dbo.ResumeToVacancy RTV WITH (NOLOCK) ON VSA.VacancyID = RTV.VacancyId
	WHERE CHARINDEX(',' + CAST(C.SynonymousID AS VARCHAR) + ',', ',' + VSA.SynonymousIDs + ',') > 0
	 AND CHARINDEX(',' + CAST(C.CityID AS VARCHAR) + ',', ',' + VSA.CityIDs + ',') > 0
	 AND VSA.IsNewForSubscription = 1
	 AND RTV.AddDate BETWEEN @PoolDate + 1 AND @PoolDate + 2) AS ResponsesCount_New
 , (SELECT COUNT(*)
    FROM Analytics.dbo.VacancySubscriptionActual VSA WITH (NOLOCK)
	 JOIN Analytics.dbo.VacancyApplyToVacancy VATV WITH (NOLOCK) ON VSA.VacancyID = VATV.VacancyId
	WHERE CHARINDEX(',' + CAST(C.SynonymousID AS VARCHAR) + ',', ',' + VSA.SynonymousIDs + ',') > 0
	 AND CHARINDEX(',' + CAST(C.CityID AS VARCHAR) + ',', ',' + VSA.CityIDs + ',') > 0
	 AND VSA.IsNewForSubscription = 0
	 AND VATV.AddDate BETWEEN @PoolDate + 1 AND @PoolDate + 2) 
	 +
   (SELECT COUNT(*)
    FROM Analytics.dbo.VacancySubscriptionActual VSA WITH (NOLOCK)
	 JOIN Analytics.dbo.ResumeToVacancy RTV WITH (NOLOCK) ON VSA.VacancyID = RTV.VacancyId
	WHERE CHARINDEX(',' + CAST(C.SynonymousID AS VARCHAR) + ',', ',' + VSA.SynonymousIDs + ',') > 0
	 AND CHARINDEX(',' + CAST(C.CityID AS VARCHAR) + ',', ',' + VSA.CityIDs + ',') > 0
	 AND VSA.IsNewForSubscription = 0
	 AND RTV.AddDate BETWEEN @PoolDate + 1 AND @PoolDate + 2) AS ResponsesCount_Upd
FROM #C C

DROP TABLE #C;