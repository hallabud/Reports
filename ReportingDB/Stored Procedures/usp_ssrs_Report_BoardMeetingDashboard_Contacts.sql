CREATE PROCEDURE dbo.usp_ssrs_Report_BoardMeetingDashboard_Contacts
	@YearNum INT

AS

SELECT D.YearNum, D.MonthNum, D.MonthNameEng, COUNT(*) AS ContactsOpened
FROM Analytics.dbo.DailyViewedResume DVR
 JOIN Reporting.dbo.DimDate D ON DVR.ViewDate = D.FullDate
WHERE D.YearNum = @YearNum
GROUP BY D.YearNum, D.MonthNum, D.MonthNameEng
ORDER BY D.YearNum, D.MonthNum;