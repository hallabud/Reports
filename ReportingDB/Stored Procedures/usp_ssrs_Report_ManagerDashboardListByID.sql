--DECLARE @NotebookId INT; SET @NotebookId = 720;
--DECLARE @Mode TINYINT; SET @Mode = 3;


CREATE PROCEDURE [dbo].[usp_ssrs_Report_ManagerDashboardListByID] (@NotebookID INT, @Mode TINYINT)

AS
-- Modes: 1 - Monthly, 2 - Weekly, 3 - Daily;

IF @Mode = 1
BEGIN
	SELECT
	   (SELECT TOP 1 CompleteDate FROM Analytics.dbo.CRM_Action A WHERE A.NotebookID = DC.NotebookId AND StateID = 2 AND IsNotInterested = 0 ORDER BY CompleteDate DESC) AS LastCompletedDate
	 , (SELECT TOP 1 ResultComment FROM Analytics.dbo.CRM_Action A WHERE A.NotebookID = DC.NotebookId AND StateID = 2 AND IsNotInterested = 0 ORDER BY CompleteDate DESC) AS LastCompletedResultComment
	 , (SELECT TOP 1 ExecutionDate FROM Analytics.dbo.CRM_Action A WHERE A.NotebookID = DC.NotebookId AND StateID IN (1,4) ORDER BY ExecutionDate ASC) AS NextActionDate
	 , (SELECT TOP 1 Subject FROM Analytics.dbo.CRM_Action A WHERE A.NotebookID = DC.NotebookId AND StateID IN (1,4) ORDER BY ExecutionDate ASC) AS NextActionComment
	 , DD.FullDate
	 , DC.Company_key
	 , DC.CompanyName
	 , DC.NotebookId
	 , DC.WorkCompanyID
	 , DC.WorkConnectionGroup
	 , DC.IndexAttraction
	 , DC.AvgLast3Month
	 , CASE WHEN DD.FullDate <= '2014-08-01' THEN ISNULL(FCS.FakeVacancyNum,0) ELSE ISNULL(FCS.VacancyNum,0) END AS VacancyNum
	 , ISNULL(FCS.WorkVacancyNum,0) AS WorkVacancyNum
	 , CASE WHEN DD.FullDate <= '2014-08-01' THEN ISNULL(FCS.FakeVacancyNum,0) - ISNULL(FCS.WorkVacancyNum,0) ELSE ISNULL(FCS.VacancyNum,0) - ISNULL(FCS.WorkVacancyNum,0) END AS VacancyDiff
	 , CASE WHEN DD.FullDate <= '2014-08-01' THEN COALESCE(FCS.FakeVacancyDiffGroup, FCS.VacancyDiffGroup) ELSE FCS.VacancyDiffGroup END AS VacancyDiffGroup
	 , CASE 
		WHEN DC.IndexAttraction BETWEEN 7 AND 10 THEN '*****' 
		WHEN DC.IndexAttraction BETWEEN 4.5 AND 7 THEN '****' 
		WHEN DC.IndexAttraction BETWEEN 3 AND 4.5 THEN '***'
		WHEN DC.IndexAttraction BETWEEN 1 AND 3 THEN '**'
		WHEN DC.IndexAttraction > 0 THEN '*'
		ELSE '-'
	   END AS Stars
	 , CASE WHEN DD.FullDate <= '2014-08-01' AND COALESCE(FCS.FakeVacancyDiffGroup, FCS.VacancyDiffGroup) = 'R > W = 0' THEN 1 WHEN DD.FullDate > '2014-08-01' AND FCS.VacancyDiffGroup = 'R > W = 0' THEN 1 ELSE 0 END AS VacancyDiff1
	 , CASE WHEN DD.FullDate <= '2014-08-01' AND COALESCE(FCS.FakeVacancyDiffGroup, FCS.VacancyDiffGroup) = 'R > W > 0' THEN 1 WHEN DD.FullDate > '2014-08-01' AND FCS.VacancyDiffGroup = 'R > W > 0' THEN 1 ELSE 0 END AS VacancyDiff2
	 , CASE WHEN DD.FullDate <= '2014-08-01' AND COALESCE(FCS.FakeVacancyDiffGroup, FCS.VacancyDiffGroup) = 'R = W' THEN 1 WHEN DD.FullDate > '2014-08-01' AND FCS.VacancyDiffGroup = 'R = W' THEN 1 ELSE 0 END AS VacancyDiff3
	 , CASE WHEN DD.FullDate <= '2014-08-01' AND COALESCE(FCS.FakeVacancyDiffGroup, FCS.VacancyDiffGroup) = '0 < R < W' THEN 1 WHEN DD.FullDate > '2014-08-01' AND FCS.VacancyDiffGroup = '0 < R < W' THEN 1 ELSE 0 END AS VacancyDiff4
	 , CASE WHEN DD.FullDate <= '2014-08-01' AND COALESCE(FCS.FakeVacancyDiffGroup, FCS.VacancyDiffGroup) = '0 = R < W' THEN 1 WHEN DD.FullDate > '2014-08-01' AND FCS.VacancyDiffGroup = '0 = R < W' THEN 1 ELSE 0 END AS VacancyDiff5
	 , CASE WHEN DD.FullDate <= '2014-08-01' AND COALESCE(FCS.FakeVacancyDiffGroup, FCS.VacancyDiffGroup) = 'R = W = 0' THEN 1 WHEN DD.FullDate > '2014-08-01' AND FCS.VacancyDiffGroup = 'R = W = 0' THEN 1 ELSE 0 END AS VacancyDiff6
	FROM dbo.DimCompany DC
	 JOIN dbo.FactCompanyStatuses FCS ON DC.Company_key = FCS.Company_key
	 JOIN dbo.DimDate DD ON FCS.Date_key = DD.Date_key
	WHERE DD.FullDate > DATEADD(DAY, 1 - DATEPART(DAYOFYEAR, GETDATE()), GETDATE()) 
	 AND (DD.DayNum = 1 OR DD.FullDate = dbo.fnGetDatePart(GETDATE()))
	 -- AND DC.IndexAttraction > 0
	 AND DC.WorkConnectionGroup = 'Привязанные компании'
	 AND DC.NotebookId = @NotebookId
END

IF @Mode = 2
BEGIN
	SELECT 
	   (SELECT TOP 1 CompleteDate FROM Analytics.dbo.CRM_Action A WHERE A.NotebookID = DC.NotebookId AND StateID = 2 AND IsNotInterested = 0 ORDER BY CompleteDate DESC) AS LastCompletedDate
	 , (SELECT TOP 1 ResultComment FROM Analytics.dbo.CRM_Action A WHERE A.NotebookID = DC.NotebookId AND StateID = 2 AND IsNotInterested = 0 ORDER BY CompleteDate DESC) AS LastCompletedResultComment
	 , (SELECT TOP 1 ExecutionDate FROM Analytics.dbo.CRM_Action A WHERE A.NotebookID = DC.NotebookId AND StateID IN (1,4) ORDER BY ExecutionDate ASC) AS NextActionDate
	 , (SELECT TOP 1 Subject FROM Analytics.dbo.CRM_Action A WHERE A.NotebookID = DC.NotebookId AND StateID IN (1,4) ORDER BY ExecutionDate ASC) AS NextActionComment
	 , DD.FullDate
	 , DC.Company_key
	 , DC.CompanyName
	 , DC.NotebookId
	 , DC.WorkCompanyID
	 , DC.WorkConnectionGroup
	 , DC.IndexAttraction
	 , DC.AvgLast3Month
	 , FCS.VacancyNum
	 , ISNULL(FCS.WorkVacancyNum,0) AS WorkVacancyNum
	 , ISNULL(FCS.VacancyNum,0) - ISNULL(FCS.WorkVacancyNum,0) AS VacancyDiff
	 , FCS.VacancyDiffGroup AS VacancyDiffGroup
	 , CASE 
		WHEN DC.IndexAttraction BETWEEN 7 AND 10 THEN '*****' 
		WHEN DC.IndexAttraction BETWEEN 4.5 AND 7 THEN '****' 
		WHEN DC.IndexAttraction BETWEEN 3 AND 4.5 THEN '***'
		WHEN DC.IndexAttraction BETWEEN 1 AND 3 THEN '**'
		WHEN DC.IndexAttraction > 0 THEN '*'
		ELSE '-'
	   END AS Stars
	 , CASE WHEN FCS.VacancyDiffGroup = 'R > W = 0' THEN 1 ELSE 0 END AS VacancyDiff1
	 , CASE WHEN FCS.VacancyDiffGroup = 'R > W > 0' THEN 1 ELSE 0 END AS VacancyDiff2
	 , CASE WHEN FCS.VacancyDiffGroup = 'R = W' THEN 1 ELSE 0 END AS VacancyDiff3
	 , CASE WHEN FCS.VacancyDiffGroup = '0 < R < W' THEN 1 ELSE 0 END AS VacancyDiff4
	 , CASE WHEN FCS.VacancyDiffGroup = '0 = R < W' THEN 1 ELSE 0 END AS VacancyDiff5
	 , CASE WHEN FCS.VacancyDiffGroup = 'R = W = 0' THEN 1 ELSE 0 END AS VacancyDiff6
	FROM dbo.DimCompany DC
	 JOIN dbo.FactCompanyStatuses FCS ON DC.Company_key = FCS.Company_key
	 JOIN dbo.DimDate DD ON FCS.Date_key = DD.Date_key
	WHERE DD.FullDate >= DATEADD(WEEK, -12, GETDATE())
	 AND (DD.WeekDayNum = 6 OR DD.FullDate = dbo.fnGetDatePart(GETDATE()))
	 -- AND DC.IndexAttraction > 0
	 AND DC.WorkConnectionGroup = 'Привязанные компании'
	 AND DC.NotebookId = @NotebookId	
END

IF @Mode = 3
BEGIN
	SELECT 
	   (SELECT TOP 1 CompleteDate FROM Analytics.dbo.CRM_Action A WHERE A.NotebookID = DC.NotebookId AND StateID = 2 AND IsNotInterested = 0 ORDER BY CompleteDate DESC) AS LastCompletedDate
	 , (SELECT TOP 1 ResultComment FROM Analytics.dbo.CRM_Action A WHERE A.NotebookID = DC.NotebookId AND StateID = 2 AND IsNotInterested = 0 ORDER BY CompleteDate DESC) AS LastCompletedResultComment
	 , (SELECT TOP 1 ExecutionDate FROM Analytics.dbo.CRM_Action A WHERE A.NotebookID = DC.NotebookId AND StateID IN (1,4) ORDER BY ExecutionDate ASC) AS NextActionDate
	 , (SELECT TOP 1 Subject FROM Analytics.dbo.CRM_Action A WHERE A.NotebookID = DC.NotebookId AND StateID IN (1,4) ORDER BY ExecutionDate ASC) AS NextActionComment
	 , DD.FullDate
	 , DC.Company_key
	 , DC.CompanyName
	 , DC.NotebookId
	 , DC.WorkCompanyID
	 , DC.WorkConnectionGroup
	 , DC.IndexAttraction
	 , DC.AvgLast3Month
	 , FCS.VacancyNum
	 , ISNULL(FCS.WorkVacancyNum,0) AS WorkVacancyNum
	 , ISNULL(FCS.VacancyNum,0) - ISNULL(FCS.WorkVacancyNum,0) AS VacancyDiff
	 , FCS.VacancyDiffGroup AS VacancyDiffGroup
	 , CASE 
		WHEN DC.IndexAttraction BETWEEN 7 AND 10 THEN '*****' 
		WHEN DC.IndexAttraction BETWEEN 4.5 AND 7 THEN '****' 
		WHEN DC.IndexAttraction BETWEEN 3 AND 4.5 THEN '***'
		WHEN DC.IndexAttraction BETWEEN 1 AND 3 THEN '**'
		WHEN DC.IndexAttraction > 0 THEN '*'
		ELSE '-'
	   END AS Stars
	 , CASE WHEN FCS.VacancyDiffGroup = 'R > W = 0' THEN 1 ELSE 0 END AS VacancyDiff1
	 , CASE WHEN FCS.VacancyDiffGroup = 'R > W > 0' THEN 1 ELSE 0 END AS VacancyDiff2
	 , CASE WHEN FCS.VacancyDiffGroup = 'R = W' THEN 1 ELSE 0 END AS VacancyDiff3
	 , CASE WHEN FCS.VacancyDiffGroup = '0 < R < W' THEN 1 ELSE 0 END AS VacancyDiff4
	 , CASE WHEN FCS.VacancyDiffGroup = '0 = R < W' THEN 1 ELSE 0 END AS VacancyDiff5
	 , CASE WHEN FCS.VacancyDiffGroup = 'R = W = 0' THEN 1 ELSE 0 END AS VacancyDiff6
	FROM dbo.DimCompany DC
	 JOIN dbo.FactCompanyStatuses FCS ON DC.Company_key = FCS.Company_key
	 JOIN dbo.DimDate DD ON FCS.Date_key = DD.Date_key
	WHERE DD.FullDate >= DATEADD(DAY, -30, GETDATE())
	 -- AND DC.IndexAttraction > 0
	 AND DC.WorkConnectionGroup = 'Привязанные компании'
	 AND DC.NotebookId = @NotebookId	
END