CREATE PROCEDURE dbo.usp_etl_UnsubscribeMetrics

AS

WITH C AS
 (
SELECT CAST(GETDATE()-1 AS DATE) AS FullDate, 'IsFromApply' AS MetricName, COUNT(*) AS MetricValue
FROM Analytics.dbo.SubscribeCompetitor 
WHERE SourceType = 1 AND IsActive = 1

UNION ALL

SELECT CAST(GETDATE() - 1 AS DATE) AS FullDate, 'IsManual' AS MetricName, COUNT(*) AS MetricValue
FROM Analytics.dbo.SubscribeCompetitor 
WHERE SourceType = 6 AND IsActive = 1

UNION ALL

SELECT CAST(GETDATE() - 1 AS DATE) AS FullDate, 'IsSend_Admin4_SeekerType1', COUNT(*)
FROM Analytics.dbo.EMailSource
WHERE IsSend_Admin4_SeekerType1 = 0

UNION ALL

SELECT CAST(GETDATE() - 1 AS DATE) AS FullDate, 'IsSend_Admin4_SeekerType2', COUNT(*)
FROM Analytics.dbo.EMailSource
WHERE IsSend_Admin4_SeekerType2 = 0

UNION ALL

SELECT CAST(GETDATE() - 1 AS DATE) AS FullDate, 'IsSend_Admin4_SeekerType3', COUNT(*)
FROM Analytics.dbo.EMailSource
WHERE IsSend_Admin4_SeekerType3 = 0

UNION ALL

SELECT CAST(GETDATE() - 1 AS DATE) AS FullDate, 'IsSend_Admin4_SeekerType4', COUNT(*)
FROM Analytics.dbo.EMailSource
WHERE IsSend_Admin4_SeekerType4 = 0
 )
INSERT INTO Reporting.dbo.AggrUnsubscribeMetrics
SELECT FullDate, [IsFromApply], [IsManual], [IsSend_Admin4_SeekerType1], [IsSend_Admin4_SeekerType2], [IsSend_Admin4_SeekerType3], [IsSend_Admin4_SeekerType4]
FROM C
PIVOT
(
SUM(MetricValue)
FOR MetricName IN ([IsFromApply], [IsManual], [IsSend_Admin4_SeekerType1], [IsSend_Admin4_SeekerType2], [IsSend_Admin4_SeekerType3], [IsSend_Admin4_SeekerType4])
) AS pvt
