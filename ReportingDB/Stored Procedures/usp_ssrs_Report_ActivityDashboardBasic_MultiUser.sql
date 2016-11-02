
CREATE PROCEDURE [dbo].[usp_ssrs_Report_ActivityDashboardBasic_MultiUser] (@NotebookID INT)

AS

DECLARE @TodayDate DATETIME = dbo.fnGetDatePart(GETDATE());
DECLARE @StartDate DATETIME = DATEADD(DAY, 1 - DAY(DATEADD(MONTH, -6, @TodayDate)), DATEADD(MONTH, -6, @TodayDate));

DECLARE @Publications TABLE (NotebookID INT, FullDate DATETIME, IsRabotaManager_Publisher BIT, MultiUserID INT, PubNum INT);
DECLARE @ResumeViews TABLE (NotebookID INT, FullDate DATETIME, MultiUserID INT, ViewNum INT);

DECLARE @Responses TABLE (FullDate DATETIME, IsViewed BIT, RespNum INT);

--DECLARE @NotebookID INT = 339772;

INSERT INTO @Publications
SELECT NotebookID, dbo.fnGetDatePart(AddDate), IsRabotaManager_Publisher, MultiUserID, COUNT(*)
FROM Analytics.dbo.NotebookCompany_Spent
WHERE NotebookID = @NotebookID
 AND SpendType <> 5
 AND AddDate BETWEEN @StartDate AND @TodayDate
GROUP BY NotebookID, dbo.fnGetDatePart(AddDate), IsRabotaManager_Publisher, MultiUserID;

INSERT INTO @ResumeViews
SELECT NotebookID, dbo.fnGetDatePart(AddDate), MultiUserID, COUNT(*)
FROM Analytics.dbo.NotebookCompanyResumeView NCRV
WHERE NotebookID = @NotebookID 
 AND AddDate BETWEEN @StartDate AND @TodayDate
GROUP BY NotebookID, dbo.fnGetDatePart(AddDate), MultiUserID

SELECT 
   DC.NotebookId
 , DC.CompanyName
 , DC.VacancyDiffGroup
 , DC.IndexAttraction
 , MU.ID AS MultiUserID
 , MU.Name AS MultiUserName
 , DD.FullDate
 , DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.WeekNum
 , DD.WeekName
 , DD.DayNum
 , DD.WeekDayNum
 , ISNULL((SELECT SUM(PubNum) FROM @Publications WHERE FullDate = DD.FullDate AND MultiUserID = MU.ID),0) AS PubNum
 , ISNULL((SELECT SUM(PubNum) FROM @Publications WHERE FullDate = DD.FullDate AND IsRabotaManager_Publisher = 1 AND MultiUserID = MU.ID),0) AS PubNum_RabotaManager
 , ISNULL((SELECT SUM(ViewNum) FROM @ResumeViews RV WHERE RV.FullDate = DD.FullDate AND RV.MultiUserID = MU.ID),0) AS ResumeViewNum
 , (SELECT COUNT(*) FROM Analytics.dbo.DailyViewedResume DVR WHERE DVR.ViewDate = DD.FullDate AND DVR.EmployerNotebookID = @NotebookID) AS OpenedContactsNum
 , (SELECT COUNT(*) FROM Analytics.dbo.SearchTemplate ST WHERE ST.MultiUserID = MU.ID AND ST.AddDate <= DD.FullDate AND IsVisible = 1) AS ResumeTemplatesNum
FROM dbo.DimCompany DC
 JOIN Analytics.dbo.MultiUser MU ON DC.NotebookID = MU.NotebookID
 JOIN dbo.DimDate DD ON DD.FullDate BETWEEN @StartDate AND @TodayDate
WHERE DC.NotebookId = @NotebookID ;