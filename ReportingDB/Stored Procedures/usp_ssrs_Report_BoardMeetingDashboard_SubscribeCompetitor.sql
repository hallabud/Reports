CREATE PROCEDURE [dbo].[usp_ssrs_Report_BoardMeetingDashboard_SubscribeCompetitor]
	@YearNum INT

AS

SELECT YearNum, AMMM.MonthNum, M.MonthNameEng, AMMM.SubscribeCompetitor_EmailCount
FROM AggrManagementMetricsMonthly AMMM
 JOIN (SELECT DISTINCT MonthNum, MonthNameEng FROM DimDate) M ON AMMM.MonthNum = M.MonthNum
WHERE YearNum = @YearNum