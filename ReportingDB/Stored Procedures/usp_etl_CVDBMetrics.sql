-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_etl_CVDBMetrics]

AS

BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON;

DECLARE @StartDate DATETIME = Analytics.dbo.fnGetDatePart(GETDATE() - 1);
DECLARE @EndDate DATETIME = Analytics.dbo.fnGetDatePart(GETDATE() - 1);

WITH C AS
	(
-- К-во просмотренных резюме
SELECT Analytics.dbo.fnGetDatePart(AddDate) AS FullDate, 'ResumeViewedCount' AS MetricName, COUNT(*) AS MetricValue
FROM SRV16.RabotaUA2.dbo.NotebookCompanyResumeView NCRV
WHERE AddDate BETWEEN @StartDate AND @EndDate + 1
GROUP BY Analytics.dbo.fnGetDatePart(AddDate)

UNION ALL

-- Кол-во просмотренных резюме работодателями

SELECT Analytics.dbo.fnGetDatePart(AddDate) AS FullDate, 'ResumeViewedByCompanyCount' AS MetricName, COUNT(*) AS MetricValue
FROM SRV16.RabotaUA2.dbo.NotebookCompanyResumeView NCRV
WHERE AddDate BETWEEN @StartDate AND @EndDate + 1
 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompany WHERE NotebookID = NCRV.NotebookID)
GROUP BY Analytics.dbo.fnGetDatePart(AddDate)

UNION ALL

-- К-во открытых контактов
SELECT ViewDate, 'ContactsOpenedCount', COUNT(*)
FROM SRV16.RabotaUA2.dbo.DailyViewedResume
WHERE ViewDate BETWEEN @StartDate AND @EndDate
GROUP BY ViewDate

UNION ALL

-- Средняя скорость отработки запроса - Средняя скорость открытия страницы
SELECT Analytics.dbo.fnGetDatePart(Date), 'PageTimeAvg', Time_Avg
FROM SRV16.RabotaUA2.dbo.Monitor_SitePage WITH(NOLOCK)
WHERE PageID = 5
	AND Analytics.dbo.fnGetDatePart(Date) BETWEEN @StartDate AND @EndDate

UNION ALL

-- К-во всех работодателей (!не использующих платные сервисы), которые воспользовались поиском по CVDB за сутки хотя бы 1 раз
SELECT Analytics.dbo.fnGetDatePart(AddDate), 'CompanyFree_HasResumeViews', COUNT(DISTINCT NotebookID)
FROM SRV16.RabotaUA2.dbo.NotebookCompanyResumeView NCRV
WHERE AddDate BETWEEN @StartDate AND @EndDate + 1
	AND NOT EXISTS (SELECT *
					FROM Analytics.dbo.TemporalPayment TP
					WHERE TP.NotebookID = NCRV.NotebookID
					AND NCRV.AddDate BETWEEN TP.StartDate AND TP.EndDate)
GROUP BY Analytics.dbo.fnGetDatePart(AddDate)

UNION ALL

-- К-во просмотров резюме работодателями (!не использующих платные сервисы)
SELECT Analytics.dbo.fnGetDatePart(AddDate), 'CompanyFree_ResumeViewedCount', COUNT(*)
FROM SRV16.RabotaUA2.dbo.NotebookCompanyResumeView NCRV
WHERE AddDate BETWEEN @StartDate AND @EndDate + 1
	AND NOT EXISTS (SELECT *
					FROM SRV16.RabotaUA2.dbo.TemporalPayment TP
					WHERE TP.NotebookID = NCRV.NotebookID
					AND NCRV.AddDate BETWEEN TP.StartDate AND TP.EndDate)
GROUP BY Analytics.dbo.fnGetDatePart(AddDate)


UNION ALL

-- К-во работодателей (!не использующих платный доступ к базе), которые исчерпали свой дневной лимит 5 возможных открытых контактов 
SELECT ViewDate, 'CompanyFree_HasFiveOpenedContacts', COUNT(DISTINCT DVR.EmployerNotebookID)
FROM SRV16.RabotaUA2.dbo.DailyViewedResume DVR
WHERE ViewDate BETWEEN @StartDate AND @EndDate
	AND NOT EXISTS (SELECT *
					FROM SRV16.RabotaUA2.dbo.TemporalPayment TP
					WHERE TP.NotebookID = DVR.EmployerNotebookID
					AND DVR.ViewDate BETWEEN TP.StartDate AND TP.EndDate)
	AND EXISTS (SELECT COUNT(*) 
				FROM SRV16.RabotaUA2.dbo.DailyViewedResume DVR2 
				WHERE DVR.EmployerNotebookID = DVR2.EmployerNotebookID 
				AND DVR.ViewDate = DVR2.ViewDate 
				HAVING COUNT(*) >= 5)
GROUP BY ViewDate

UNION ALL

-- К-во работодателей(!не использующих платный доступ к базе), которые ежедневно исчерпывают свой дневной лимит на открытие 5 бесплатных контактов в течение недели
SELECT ViewDate, 'CompanyFree_HasFiveOpenedContacts_Week', COUNT(DISTINCT DVR.EmployerNotebookID)
FROM SRV16.RabotaUA2.dbo.DailyViewedResume DVR
WHERE ViewDate BETWEEN @StartDate AND @EndDate
	AND NOT EXISTS (SELECT *
					FROM SRV16.RabotaUA2.dbo.TemporalPayment TP
					WHERE TP.NotebookID = DVR.EmployerNotebookID
					AND DVR.ViewDate BETWEEN TP.StartDate AND TP.EndDate)
	AND EXISTS (SELECT COUNT(*) 
				FROM SRV16.RabotaUA2.dbo.DailyViewedResume DVR2 
				WHERE DVR.EmployerNotebookID = DVR2.EmployerNotebookID 
				AND DVR2.ViewDate BETWEEN DATEADD(DAY, -6, DVR.ViewDate) AND DVR.ViewDate 
				AND DVR2.IsTemporalAccess = 0
				HAVING COUNT(*) >= 35)
GROUP BY ViewDate

UNION ALL

-- К-во работодателей, которые используют любой платный сервис доступа к CVDB
SELECT FullDate, 'CompanyPaidCount'
	, (SELECT COUNT(DISTINCT NotebookID) FROM SRV16.RabotaUA2.dbo.TemporalPayment WHERE DD.FullDate BETWEEN StartDate AND EndDate)
FROM Reporting.dbo.DimDate DD
WHERE FullDate BETWEEN @StartDate AND @EndDate

UNION ALL

-- К-во работодателей, которые используют unlim доступ к CVDB
SELECT FullDate, 'CompanyPaidCount_Unlim'
	, (SELECT COUNT(DISTINCT NotebookID) FROM SRV16.RabotaUA2.dbo.TemporalPayment WHERE DD.FullDate BETWEEN StartDate AND EndDate AND RubricID1 IS NULL AND CityID IS NULL)
FROM Reporting.dbo.DimDate DD
WHERE FullDate BETWEEN @StartDate AND @EndDate
	
UNION ALL

-- Количество компаний (платных + бесплатных), открывших хоть один контакт
SELECT DVR.ViewDate, 'Company_HasOpenedOneContact', COUNT(DISTINCT DVR.EmployerNotebookID)
FROM SRV16.RabotaUA2.dbo.DailyViewedResume DVR
WHERE DVR.ViewDate BETWEEN @StartDate AND @EndDate --@StartDate AND @EndDate
GROUP BY DVR.ViewDate
	)

INSERT INTO Reporting.dbo.AggrCVDBMetrics
SELECT FullDate
	, [ResumeViewedCount]
	, [ResumeViewedByCompanyCount]
	, [ContactsOpenedCount]
	, [PageTimeAvg]
	, [CompanyFree_HasResumeViews]
	, [CompanyFree_ResumeViewedCount] 
	, [CompanyFree_HasFiveOpenedContacts]
	, [CompanyFree_HasFiveOpenedContacts_Week]
	, [CompanyPaidCount]
	, [CompanyPaidCount_Unlim]
	, [Company_HasOpenedOneContact]
FROM C
PIVOT 
	(
	SUM(MetricValue)
	FOR MetricName IN (
		  [ResumeViewedCount]
		, [ResumeViewedByCompanyCount]
		, [ContactsOpenedCount]
		, [PageTimeAvg]
		, [CompanyFree_HasResumeViews]
		, [CompanyFree_ResumeViewedCount]
		, [CompanyFree_HasFiveOpenedContacts]
		, [CompanyFree_HasFiveOpenedContacts_Week]
		, [CompanyPaidCount]
		, [CompanyPaidCount_Unlim]
		, [Company_HasOpenedOneContact])
	) AS PivotTable

END
