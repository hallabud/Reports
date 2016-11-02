CREATE PROCEDURE [dbo].[usp_etl_JobAlertMetrics]

AS

DECLARE @ReportDate DATETIME

SET @ReportDate = Analytics.dbo.fnGetDatePart(GETDATE() - 1);

IF OBJECT_ID('tempdb..#C','U') IS NOT NULL DROP TABLE #C;

-- К-во e-mails, которые подписаны на JA - не по компаниям
SELECT 
   @ReportDate AS FullDate
 , 'EmailsSubscribed_NotCompany' AS MetricName
 , COUNT(DISTINCT UserEMail) AS MetricValue
INTO #C
FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor WITH (NOLOCK)
WHERE IsActive = 1
 AND CompanyNotebookID IS NULL

UNION ALL

-- К-во e-mails, которые подписаны на JA - по компаниям
SELECT 
   @ReportDate AS FullDate
 , 'EmailsSubscribed_Company' AS MetricName
 , COUNT(DISTINCT UserEMail) AS MetricValue
FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor WITH (NOLOCK)
WHERE IsActive = 1
 AND CompanyNotebookID IS NOT NULL

UNION ALL

-- Кол-во активных рассылок - не по компаниям
SELECT 
   @ReportDate AS FullDate
 , 'SubscriptionCount_NotCompany' AS MetricName
 , COUNT(*) AS MetricValue
FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor WITH (NOLOCK)
WHERE IsActive = 1
 AND CompanyNotebookID IS NULL

UNION ALL

-- Кол-во активных рассылок - по компаниям
SELECT 
   @ReportDate AS FullDate
 , 'SubscriptionCount_Company' AS MetricName
 , COUNT(*) AS MetricValue
FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor WITH (NOLOCK)
WHERE IsActive = 1
 AND CompanyNotebookID IS NOT NULL

UNION ALL

-- К-во емейлов, на которые были отправлены алерты - не по компаниям
SELECT 
   @ReportDate AS FullDate
 , 'EmailsSent_NotCompany' AS MetricName
 , COUNT(DISTINCT UserEMail) AS MetricValue
FROM SRV16.RabotaUA2.dbo.VacancySubscription_List WITH (NOLOCK)
WHERE CompanyNotebookID = 0

UNION ALL

-- К-во емейлов, на которые были отправлены алерты - по компаниям
SELECT 
   @ReportDate AS FullDate
 , 'EmailsSent_Company' AS MetricName
 , COUNT(DISTINCT UserEMail) AS MetricValue
FROM SRV16.RabotaUA2.dbo.VacancySubscription_List WITH (NOLOCK)
WHERE CompanyNotebookID <> 0

UNION ALL

-- Кол-во сформированных рассылок - не по компаниям
SELECT 
   @ReportDate AS FullDate
 , 'LettersSent_NotCompany' AS MetricName
 , COUNT(*) AS MetricValue
FROM SRV16.RabotaUA2.dbo.VacancySubscription_List WITH (NOLOCK)
WHERE CompanyNotebookID = 0

UNION ALL

-- Кол-во сформированных рассылок - по компаниям
SELECT 
   @ReportDate AS FullDate
 , 'LettersSent_Company' AS MetricName
 , COUNT(*) AS MetricValue
FROM SRV16.RabotaUA2.dbo.VacancySubscription_List WITH (NOLOCK)
WHERE CompanyNotebookID <> 0

UNION ALL

--К-во e-mails c которых был просмотр или переход - не по компаниям
SELECT @ReportDate AS FullDate
 , 'EmailsViewedOrSiteViewed_NotCompany' AS MetricName
 , COUNT(DISTINCT UserEMail)
FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor WITH (NOLOCK)
WHERE (ISNULL(Analytics.dbo.fnGetDatePart(LastViewDate), '1900-01-01') = @ReportDate OR ISNULL(Analytics.dbo.fnGetDatePart(LastViewPictureDate), '1900-01-01') = @ReportDate)
 AND IsActive = 1
 AND CompanyNotebookID IS NULL

UNION ALL

-- К-во e-mails c которых был просмотр или переход - по компаниям
SELECT @ReportDate AS FullDate
 , 'EmailsViewedOrSiteViewed_Company' AS MetricName
 , COUNT(DISTINCT UserEMail)
FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor WITH (NOLOCK)
WHERE (ISNULL(Analytics.dbo.fnGetDatePart(LastViewDate), '1900-01-01') = @ReportDate OR ISNULL(Analytics.dbo.fnGetDatePart(LastViewPictureDate), '1900-01-01') = @ReportDate)
 AND IsActive = 1
 AND CompanyNotebookID IS NOT NULL

UNION ALL

--К-во писем c которых был просмотр или переход - не по компаниям
SELECT @ReportDate AS FullDate
 , 'LetterViewedOrSiteViewed_NotCompany' AS MetricName
 , COUNT(*)
FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor WITH (NOLOCK)
WHERE (ISNULL(Analytics.dbo.fnGetDatePart(LastViewDate), '1900-01-01') = @ReportDate OR ISNULL(Analytics.dbo.fnGetDatePart(LastViewPictureDate), '1900-01-01') = @ReportDate)
 AND IsActive = 1
 AND CompanyNotebookID IS NULL

UNION ALL

-- К-во писем c которых был просмотр или переход - по компаниям
SELECT @ReportDate AS FullDate
 , 'LetterViewedOrSiteViewed_Company' AS MetricName
 , COUNT(*)
FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor WITH (NOLOCK)
WHERE (ISNULL(Analytics.dbo.fnGetDatePart(LastViewDate), '1900-01-01') = @ReportDate OR ISNULL(Analytics.dbo.fnGetDatePart(LastViewPictureDate), '1900-01-01') = @ReportDate)
 AND IsActive = 1
 AND CompanyNotebookID IS NOT NULL

UNION ALL

-- К-во e-mails с которых был переход - не по компаниям
SELECT @ReportDate AS FullDate
 , 'EmailsSiteViewed_NotCompany' AS MetricName
 , COUNT(DISTINCT UserEMail)
FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor WITH (NOLOCK)
WHERE ISNULL(Analytics.dbo.fnGetDatePart(LastViewDate), '1900-01-01') = @ReportDate
 AND IsActive = 1
 AND CompanyNotebookID IS NULL

UNION ALL

-- К-во e-mails с которых был переход - по компаниям
SELECT @ReportDate AS FullSDate
 , 'EmailsSiteViewed_Company' AS MetricName
 , COUNT(DISTINCT UserEMail)
FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor WITH (NOLOCK)
WHERE ISNULL(Analytics.dbo.fnGetDatePart(LastViewDate), '1900-01-01') = @ReportDate
 AND IsActive = 1
 AND CompanyNotebookID IS NOT NULL

UNION ALL

-- К-во писем с которых был переход - не по компаниям
SELECT @ReportDate AS FullDate
 , 'LetterSiteViewed_NotCompany' AS MetricName
 , COUNT(*)
FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor WITH (NOLOCK)
WHERE ISNULL(Analytics.dbo.fnGetDatePart(LastViewDate), '1900-01-01') = @ReportDate
 AND IsActive = 1
 AND CompanyNotebookID IS NULL

UNION ALL

-- К-во писем с которых был переход - по компаниям
SELECT @ReportDate AS FullDate
 , 'LetterSiteViewed_Company' AS MetricName
 , COUNT(*)
FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor WITH (NOLOCK)
WHERE ISNULL(Analytics.dbo.fnGetDatePart(LastViewDate), '1900-01-01') = @ReportDate
 AND IsActive = 1
 AND CompanyNotebookID IS NOT NULL

UNION ALL

--# (13 цель из GA)
SELECT @ReportDate
 , 'ga_goal13Completions'
 , FI.Value
FROM Reporting.dbo.GA_Fact_Indexes FI
 JOIN Reporting.dbo.GA_Lookup_Indexes LI ON FI.IndexID = LI.ID
WHERE Analytics.dbo.fnGetDatePart(FI.AddDate) = @ReportDate - 1
 AND IndexName = 'ga:goal13Completions'

UNION ALL

-- Кол-во вакансий в пуле
SELECT @ReportDate AS FullDate
 , 'VacancyPoolCount' AS MetricName
 , COUNT(*)
FROM SRV16.RabotaUA2.dbo.VacancySubscriptionActual WITH (NOLOCK)
 
--UNION ALL

---- К-во обновленных вакансий, которые не попали в рассылку вообще
--SELECT @ReportDate AS FullDate
-- , 'NotNewForSubscription' AS MetricName
-- , COUNT(*)
--FROM SRV16.RabotaUA2.dbo.VacancySubscriptionActual VSA WITH (NOLOCK)
--WHERE IsNewForSubscription = 0
-- AND NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.VacancySubscription WITH (NOLOCK) WHERE CHARINDEX(',' + CAST(VSA.VacancyID AS VARCHAR) + ',',',' + VacancyIDs + ',') > 0)

--UNION ALL

---- К-во новых вакансий, которые не попали в рассылку вообще
--SELECT @ReportDate AS FullDate
-- , 'IsNewForSubscription' AS MetricName
-- , COUNT(*)
--FROM SRV16.RabotaUA2.dbo.VacancySubscriptionActual VSA WITH (NOLOCK)
--WHERE IsNewForSubscription = 1
-- AND NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.VacancySubscription WITH (NOLOCK) WHERE CHARINDEX(',' + CAST(VSA.VacancyID AS VARCHAR) + ',',',' + VacancyIDs + ',') > 0) 

INSERT INTO Reporting.dbo.AggrJobAlertMetrics
SELECT
   FullDate
 , [EmailsSubscribed_NotCompany] AS EmailsSubscribed_NotCompany
 , [EmailsSubscribed_Company] AS EmailsSubscribed_Company
 , [SubscriptionCount_NotCompany] AS SubscriptionCount_NotCompany
 , [SubscriptionCount_Company] AS SubscriptionCount_Company
 , [EmailsSent_NotCompany] AS EmailsSent_NotCompany
 , [EmailsSent_Company] AS EmailsSent_Company
 , [LettersSent_NotCompany] AS LettersSent_NotCompany
 , [LettersSent_Company] AS LettersSent_Company
 , [EmailsViewedOrSiteViewed_NotCompany] AS EmailsViewedOrSiteViewed_NotCompany
 , [EmailsViewedOrSiteViewed_Company] AS EmailsViewedOrSiteViewed_Company
 , [LetterViewedOrSiteViewed_NotCompany] AS LetterViewedOrSiteViewed_NotCompany
 , [LetterViewedOrSiteViewed_Company] AS LetterViewedOrSiteViewed_Company
 , [EmailsSiteViewed_NotCompany] AS EmailsSiteViewed_NotCompany
 , [EmailsSiteViewed_Company] AS EmailsSiteViewed_Company
 , [LetterSiteViewed_NotCompany] AS LetterSiteViewed_NotCompany
 , [LetterSiteViewed_Company] AS LetterSiteViewed_Company
 , [ga_goal13Completions] AS 'ga_goal13Completions'
 , [VacancyPoolCount] AS VacancyPoolCount
FROM #C
PIVOT
(
SUM(MetricValue)
FOR MetricName IN ([EmailsSubscribed_NotCompany]
				 , [EmailsSubscribed_Company]
				 , [SubscriptionCount_NotCompany]
				 , [SubscriptionCount_Company]
				 , [EmailsSent_NotCompany]
				 , [EmailsSent_Company]
				 , [LettersSent_NotCompany]
				 , [LettersSent_Company]
				 , [EmailsViewedOrSiteViewed_NotCompany]
				 , [EmailsViewedOrSiteViewed_Company]
				 , [LetterViewedOrSiteViewed_NotCompany]
				 , [LetterViewedOrSiteViewed_Company]
				 , [EmailsSiteViewed_NotCompany]
				 , [EmailsSiteViewed_Company]
				 , [LetterSiteViewed_NotCompany]
				 , [LetterSiteViewed_Company]
				 , [ga_goal13Completions]
				 , [VacancyPoolCount])
) AS pvt;




