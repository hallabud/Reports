/****** Object:  StoredProcedure [dbo].[usp_ssrs_Report_UniqueVacancy]    Script Date: 23.03.2015 12:38:04 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO
CREATE PROCEDURE [dbo].[usp_ssrs_Report_UniqueVacancy_Dates] (@Mode TINYINT)

AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

IF OBJECT_ID('tempdb..#T','U') IS NOT NULL DROP TABLE #T;

CREATE TABLE #T (
	Id INT,
	State TINYINT,
	RabotaVacancyName VARCHAR(255),
	NotebookID INT,
	SpiderVacancyID INT,
	IsPublish BIT,
	WorkVacancyName VARCHAR(255),
	SpiderCompanyID INT,
	VacancyConnectionType VARCHAR(255),
	CityID INT);

INSERT INTO #T
SELECT 
   V.Id, V.State, V.Name AS RabotaVacancyName, V.NotebookID
 , SV.SpiderVacancyID, SV.IsPublish, SV.Name AS WorkVacancyName, SV.SpiderCompanyID
 , CASE 
    WHEN V.State = 4 AND SV.SpiderVacancyID IS NOT NULL AND SV.IsPublish = 1 THEN 'Привязанные вакансии'
	WHEN V.State <> 4 AND SV.SpiderVacancyID IS NOT NULL AND SV.IsPublish = 1 THEN 'Уникальная на work.ua - Есть неактивная на rabota.ua'
	WHEN V.ID IS NULL AND SV.SpiderVacancyID IS NOT NULL AND SV.IsPublish = 1 THEN 'Уникальная на work.ua'
	WHEN V.State = 4 AND SV.SpiderVacancyID IS NOT NULL AND SV.IsPublish = 0 THEN 'Уникальная на rabota.ua - Есть неактивная на work.ua'
	WHEN V.State = 4 AND SV.SpiderVacancyID IS NULL THEN 'Уникальная на rabota.ua'
   END AS VacancyConnectionType
 , SV.CityID
FROM SRV16.RabotaUA2.dbo.Vacancy V WITH (NOLOCK)
 FULL JOIN SRV16.RabotaUA2.dbo.SpiderVacancy SV WITH (NOLOCK) ON V.ID = SV.VacancyID AND SV.Source = 1
WHERE (V.State = 4 OR SV.IsPublish = 1)
 AND (EXISTS (SELECT * FROM Reporting.dbo.DimCompany WHERE WorkCompanyID = SV.SpiderCompanyID) OR EXISTS (SELECT * FROM Reporting.dbo.DimCompany WHERE NotebookId = V.NotebookId AND WorkCompanyID IS NOT NULL));

DELETE T1
FROM #T T1 
WHERE T1.Id IS NULL AND EXISTS (SELECT * 
								FROM #T 
								WHERE SpiderCompanyID = T1.SpiderCompanyID 
								 AND SpiderVacancyID <> T1.SpiderVacancyID 
								 AND CityID = T1.CityID 
								 AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
										WorkVacancyName, ' ' , ''), '-', ''), ',', ''), '.', ''), '(', ''), ')', ''), '/', ''), '\', '') 
									= REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
										T1.WorkVacancyName, ' ' , ''), '-', ''), ',', ''), '.', ''), '(', ''), ')', ''), '/', ''), '\', ''));

-- Дневной
IF @Mode = 3
BEGIN

	SELECT DD.FullDate, DC.DepartmentName, DC.ManagerName, DC.VacancyDiffGroup, DC.StarRating
	 , CASE 
	    WHEN DC.VacancyDiffGroup = 'R = W = 0' THEN 0
	    WHEN DC.VacancyDiffGroup = '0 = R < W' THEN 0
		ELSE SUM(ISNULL(FCS.UnqVacancyNum,0)) 
	   END AS UnqVacancyNum	   
	 , CASE 
	    WHEN DC.VacancyDiffGroup = 'R = W = 0' THEN 0
	    WHEN DC.VacancyDiffGroup = 'R > W = 0' THEN 0
		ELSE SUM(ISNULL(FCS.UnqWorkVacancyNum,0)) 
	   END AS UnqWorkVacancyNum
	 , CASE 
	    WHEN DC.VacancyDiffGroup = 'R = W = 0' THEN 0
	    WHEN DC.VacancyDiffGroup = '0 = R < W' THEN 0
		ELSE SUM(ISNULL(FCS.UnqVacancyNum,0)) 
	   END 
	    +
	   CASE 
	    WHEN DC.VacancyDiffGroup = 'R = W = 0' THEN 0
	    WHEN DC.VacancyDiffGroup = 'R > W = 0' THEN 0
		ELSE SUM(ISNULL(FCS.UnqWorkVacancyNum,0)) 
	   END AS UnqVacancyTotal
	FROM Reporting.dbo.DimCompany DC
	 JOIN Reporting.dbo.FactCompanyStatuses FCS ON DC.Company_key = FCS.Company_key
	 JOIN Reporting.dbo.DimDate DD ON FCS.Date_key = DD.Date_key
	WHERE DC.WorkConnectionGroup = 'Привязанные компании'
	 AND FCS.VacancyDiffGroup <> 'R = W = 0'
	 AND DD.FullDate BETWEEN DATEADD(DAY, -7, GETDATE()) AND GETDATE() - 1
	 AND (ISNULL(FCS.UnqVacancyNum,0) > 0 OR ISNULL(FCS.UnqWorkVacancyNum,0) > 0)
	GROUP BY DD.FullDate, DC.DepartmentName, DC.ManagerName, DC.VacancyDiffGroup, DC.StarRating

	UNION ALL

	SELECT 
	   dbo.fnGetDatePart(GETDATE()) AS FullDate
	 , COALESCE(DC1.DepartmentName, DC2.DepartmentName) AS DepartmentName
	 , COALESCE(DC1.ManagerName, DC2.ManagerName) AS ManagerName
	 , COALESCE(DC1.VacancyDiffGroup, DC2.VacancyDiffGroup) AS VacancyDiffGroup
	 , COALESCE(DC1.StarRating, DC2.StarRating) AS StarRating
	 , NULL
	 , COUNT(*) AS UnqWorkVacancyNum 
	 , NULL
	FROM #T T
	 LEFT JOIN Reporting.dbo.DimCompany DC1 ON T.NotebookId = DC1.NotebookId
	 LEFT JOIN Reporting.dbo.DimCompany DC2 ON T.SpiderCompanyId = DC2.WorkCompanyId
	WHERE T.VacancyConnectionType IN ('Уникальная на work.ua','Уникальная на work.ua - Есть неактивная на rabota.ua')
	GROUP BY
	   COALESCE(DC1.VacancyDiffGroup, DC2.VacancyDiffGroup)
	 , COALESCE(DC1.DepartmentName, DC2.DepartmentName)
	 , COALESCE(DC1.ManagerName, DC2.ManagerName)
	 , COALESCE(DC1.StarRating, DC2.StarRating);

END

-- Недельный
IF @Mode = 2
BEGIN

	SELECT DD.FullDate AS FullDate, DC.DepartmentName, DC.ManagerName, DC.VacancyDiffGroup, DC.StarRating
	 , CASE 
	    WHEN DC.VacancyDiffGroup = 'R = W = 0' THEN 0
	    WHEN DC.VacancyDiffGroup = '0 = R < W' THEN 0
		ELSE SUM(ISNULL(FCS.UnqVacancyNum,0)) 
	   END AS UnqVacancyNum	   
	 , CASE 
	    WHEN DC.VacancyDiffGroup = 'R = W = 0' THEN 0
	    WHEN DC.VacancyDiffGroup = 'R > W = 0' THEN 0
		ELSE SUM(ISNULL(FCS.UnqWorkVacancyNum,0)) 
	   END AS UnqWorkVacancyNum
	 , CASE 
	    WHEN DC.VacancyDiffGroup = 'R = W = 0' THEN 0
	    WHEN DC.VacancyDiffGroup = '0 = R < W' THEN 0
		ELSE SUM(ISNULL(FCS.UnqVacancyNum,0)) 
	   END 
	    +
	   CASE 
	    WHEN DC.VacancyDiffGroup = 'R = W = 0' THEN 0
	    WHEN DC.VacancyDiffGroup = 'R > W = 0' THEN 0
		ELSE SUM(ISNULL(FCS.UnqWorkVacancyNum,0)) 
	   END AS UnqVacancyTotal
	FROM Reporting.dbo.DimCompany DC
	 JOIN Reporting.dbo.FactCompanyStatuses FCS ON DC.Company_key = FCS.Company_key
	 JOIN Reporting.dbo.DimDate DD ON FCS.Date_key = DD.Date_key
	WHERE DC.WorkConnectionGroup = 'Привязанные компании'
	 AND FCS.VacancyDiffGroup <> 'R = W = 0'
	 AND DD.WeekDayNum = 6 
	 AND DD.FullDate BETWEEN DATEADD(WEEK, -7, GETDATE()) AND GETDATE() - 1
	 AND (ISNULL(FCS.UnqVacancyNum,0) > 0 OR ISNULL(FCS.UnqWorkVacancyNum,0) > 0)
	GROUP BY DD.FullDate, DC.DepartmentName, DC.ManagerName, DC.VacancyDiffGroup, DC.StarRating

	UNION ALL

	SELECT 
	   dbo.fnGetDatePart(GETDATE()) AS FullDate
	 , COALESCE(DC1.DepartmentName, DC2.DepartmentName) AS DepartmentName
	 , COALESCE(DC1.ManagerName, DC2.ManagerName) AS ManagerName
	 , COALESCE(DC1.VacancyDiffGroup, DC2.VacancyDiffGroup) AS VacancyDiffGroup
	 , COALESCE(DC1.StarRating, DC2.StarRating) AS StarRating
	 , NULL
	 , COUNT(*) AS UnqWorkVacancyNum 
	 , NULL
	FROM #T T
	 LEFT JOIN Reporting.dbo.DimCompany DC1 ON T.NotebookId = DC1.NotebookId
	 LEFT JOIN Reporting.dbo.DimCompany DC2 ON T.SpiderCompanyId = DC2.WorkCompanyId
	WHERE T.VacancyConnectionType IN ('Уникальная на work.ua','Уникальная на work.ua - Есть неактивная на rabota.ua')
	GROUP BY
	   COALESCE(DC1.VacancyDiffGroup, DC2.VacancyDiffGroup)
	 , COALESCE(DC1.DepartmentName, DC2.DepartmentName)
	 , COALESCE(DC1.ManagerName, DC2.ManagerName)
	 , COALESCE(DC1.StarRating, DC2.StarRating);

END

-- Месячный
IF @Mode = 1
BEGIN

	SELECT DD.FullDate AS FullDate, DC.DepartmentName, DC.ManagerName, DC.VacancyDiffGroup, DC.StarRating
	 , CASE 
	    WHEN DC.VacancyDiffGroup = 'R = W = 0' THEN 0
	    WHEN DC.VacancyDiffGroup = '0 = R < W' THEN 0
		ELSE SUM(ISNULL(FCS.UnqVacancyNum,0)) 
	   END AS UnqVacancyNum	   
	 , CASE 
	    WHEN DC.VacancyDiffGroup = 'R = W = 0' THEN 0
	    WHEN DC.VacancyDiffGroup = 'R > W = 0' THEN 0
		ELSE SUM(ISNULL(FCS.UnqWorkVacancyNum,0)) 
	   END AS UnqWorkVacancyNum
	 , CASE 
	    WHEN DC.VacancyDiffGroup = 'R = W = 0' THEN 0
	    WHEN DC.VacancyDiffGroup = '0 = R < W' THEN 0
		ELSE SUM(ISNULL(FCS.UnqVacancyNum,0)) 
	   END 
	    +
	   CASE 
	    WHEN DC.VacancyDiffGroup = 'R = W = 0' THEN 0
	    WHEN DC.VacancyDiffGroup = 'R > W = 0' THEN 0
		ELSE SUM(ISNULL(FCS.UnqWorkVacancyNum,0)) 
	   END AS UnqVacancyTotal
	FROM Reporting.dbo.DimCompany DC
	 JOIN Reporting.dbo.FactCompanyStatuses FCS ON DC.Company_key = FCS.Company_key
	 JOIN Reporting.dbo.DimDate DD ON FCS.Date_key = DD.Date_key
	WHERE DC.WorkConnectionGroup = 'Привязанные компании'
	 AND FCS.VacancyDiffGroup <> 'R = W = 0'
	 AND DD.DayNum = 1
	 AND DD.FullDate - 1 BETWEEN DATEADD(MONTH, -7, GETDATE()) AND GETDATE() - 1
	 AND (ISNULL(FCS.UnqVacancyNum,0) > 0 OR ISNULL(FCS.UnqWorkVacancyNum,0) > 0)
	GROUP BY DD.FullDate, DC.DepartmentName, DC.ManagerName, DC.VacancyDiffGroup, DC.StarRating

	UNION ALL

	SELECT 
	   dbo.fnGetDatePart(GETDATE()) AS FullDate
	 , COALESCE(DC1.DepartmentName, DC2.DepartmentName) AS DepartmentName
	 , COALESCE(DC1.ManagerName, DC2.ManagerName) AS ManagerName
	 , COALESCE(DC1.VacancyDiffGroup, DC2.VacancyDiffGroup) AS VacancyDiffGroup
	 , COALESCE(DC1.StarRating, DC2.StarRating) AS StarRating
	 , NULL
	 , COUNT(*) AS UnqWorkVacancyNum 
	 , NULL
	FROM #T T
	 LEFT JOIN Reporting.dbo.DimCompany DC1 ON T.NotebookId = DC1.NotebookId
	 LEFT JOIN Reporting.dbo.DimCompany DC2 ON T.SpiderCompanyId = DC2.WorkCompanyId
	WHERE T.VacancyConnectionType IN ('Уникальная на work.ua','Уникальная на work.ua - Есть неактивная на rabota.ua')
	GROUP BY
	   COALESCE(DC1.VacancyDiffGroup, DC2.VacancyDiffGroup)
	 , COALESCE(DC1.DepartmentName, DC2.DepartmentName)
	 , COALESCE(DC1.ManagerName, DC2.ManagerName)
	 , COALESCE(DC1.StarRating, DC2.StarRating);
END


