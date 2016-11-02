CREATE PROCEDURE [dbo].[usp_ssrs_Report_UniqueVacancy] 
	(@CompanyFilter INT)

AS

DECLARE @MayDay DATE = '2016-03-31';
DECLARE @Today DATETIME = CONVERT(DATE, GETDATE());
DECLARE @ThreeMonthAgo DATE = DATEADD(MONTH, -3, @Today);

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

 WITH C AS
  (
SELECT 
   COALESCE(DC1.VacancyDiffGroup, DC2.VacancyDiffGroup) AS VacancyDiffGroup
 , COALESCE(DC1.DepartmentName, DC2.DepartmentName) AS DepartmentName
 , COALESCE(DC1.ManagerName, DC2.ManagerName) AS ManagerName
 , T.VacancyConnectionType
 , COUNT(*) AS VacancyCount
FROM #T T
 LEFT JOIN Reporting.dbo.DimCompany DC1 ON T.NotebookId = DC1.NotebookId
 LEFT JOIN Reporting.dbo.DimCompany DC2 ON T.SpiderCompanyId = DC2.WorkCompanyId
WHERE (COALESCE(DC1.ManagerStartDate, DC2.ManagerStartDate) <= CASE WHEN @CompanyFilter = 1 THEN @Today ELSE @MayDay END OR COALESCE(DC1.ManagerStartDate, DC2.ManagerStartDate) <= CASE WHEN @CompanyFilter = 1 THEN @Today ELSE @ThreeMonthAgo END) -- Компания взята в работу менеджером или до 1/04/2016, или не позже чем 3 мес. назад
GROUP BY
   COALESCE(DC1.VacancyDiffGroup, DC2.VacancyDiffGroup)
 , COALESCE(DC1.DepartmentName, DC2.DepartmentName)
 , COALESCE(DC1.ManagerName, DC2.ManagerName)
 , T.VacancyConnectionType
 )
SELECT 'rabota.ua' AS Website,
   C.*
FROM C
WHERE VacancyConnectionType IN ('Уникальная на rabota.ua')

UNION ALL 

SELECT 'work.ua' AS Website,
   C.*
FROM C
WHERE VacancyConnectionType IN ('Уникальная на work.ua')

UNION ALL

SELECT 'rabota.ua' AS Website,
   C.*
FROM C
WHERE VacancyConnectionType IN ('Привязанные вакансии','Уникальная на rabota.ua - Есть неактивная на work.ua')

UNION ALL

SELECT 'work.ua' AS Website,
   C.*
FROM C
WHERE VacancyConnectionType IN ('Привязанные вакансии','Уникальная на work.ua - Есть неактивная на rabota.ua')

UNION ALL

SELECT 'Total' AS Website,
   C.*
FROM C
;