
CREATE PROCEDURE [dbo].[usp_ssrs_Report_WorkVsRabota_Cities_Comparsion] (@CityID INT)

AS

 --расчетный регион компании
 
IF OBJECT_ID('tempdb..#SpiderCompanyHeadquarterCity','U') IS NOT NULL DROP TABLE #SpiderCompanyHeadquarterCity;

CREATE TABLE #SpiderCompanyHeadquarterCity 
 (CompanyID INT PRIMARY KEY
  , CompanyName VARCHAR(200)
  , IsApproved VARCHAR(20)
  , LinkedNotebookID INT
  , IsLinked VARCHAR(20)
  , SalesChannel VARCHAR(200)
  , WebsiteExists VARCHAR(20)
  , CityID INT);

INSERT INTO #SpiderCompanyHeadquarterCity
SELECT SpiderCompanyID, CompanyName, IsApproved, NotebookID, IsLinked, SalesChannel, WebsiteExists, CityID
FROM
(
SELECT SV.SpiderCompanyID, SC.Name AS CompanyName
 , CASE SC.IsApproved WHEN 1 THEN 'Проверенная' ELSE 'Непроверенная' END AS IsApproved
 , SC.NotebookId 
 , CASE WHEN SC.NotebookId IS NOT NULL THEN 'Привязанная' ELSE 'Непривязанная' END AS IsLinked
 , CASE WHEN M.DepartmentID = 2 THEN 'Sales Force' ELSE 'SMB' END AS SalesChannel
 , CASE WHEN ISNULL(SC.Site,'') <> '' THEN 'С сайтом' ELSE 'Без сайта' END AS WebsiteExists
 , SV.CityID, COUNT(*) AS VacancyNum, ROW_NUMBER() OVER(PARTITION BY SV.SpiderCompanyID ORDER BY COUNT(*) DESC, SV.CityID) AS RowNum
FROM Analytics.dbo.SpiderVacancy SV
 JOIN Analytics.dbo.SpiderCompany SC ON SV.SpiderCompanyID = SC.CompanyId AND SC.Source = 1
 JOIN Analytics.dbo.City C ON SV.CityID = C.Id
 LEFT JOIN Analytics.dbo.NotebookCompany NC ON SC.NotebookId = NC.NotebookId
 LEFT JOIN Analytics.dbo.Manager M ON NC.ManagerId = M.Id
WHERE SV.Source = 1 AND SV.SpiderCompanyID <> 0
GROUP BY SV.SpiderCompanyID, SC.Name, SC.IsApproved, SC.NotebookId, M.DepartmentID, SC.Site, SV.CityID
) AS CalcCity
WHERE RowNum = 1;

WITH C AS 
( 
SELECT 'rabota.ua' AS Source, NC.NotebookID AS CompanyID, NC.Name AS CompanyName
 , CASE N.NotebookStateId WHEN 7 THEN 'Проверенная' ELSE 'Непроверенная' END AS IsApproved
 , NULL AS LinkedNotebookID
 , NULL AS IsLinked
 , CASE WHEN M.DepartmentID = 2 THEN 'Sales Force' ELSE 'SMB' END AS SalesChannel
 , CASE WHEN ISNULL(NC.ContactURL,'') <> '' THEN 'С сайтом' ELSE 'Без сайта' END AS WebsiteExists
 , COUNT(*) AS VacancyNum
FROM Analytics.dbo.VacancyPublished VP
 JOIN Analytics.dbo.VacancyCity VC ON VP.ID = VC.VacancyId
 JOIN Analytics.dbo.City C ON VC.CityId = C.Id
 JOIN Analytics.dbo.NotebookCompany NC ON VP.NotebookID = NC.NotebookId
 JOIN Analytics.dbo.Notebook N ON NC.NotebookID = N.Id
 JOIN Analytics.dbo.Manager M ON NC.ManagerId = M.Id
WHERE /*VC.CityID = @CityID AND*/ NC.HeadquarterCityId = @CityID
GROUP BY 
   NC.NotebookID
 , NC.Name
 , CASE N.NotebookStateId WHEN 7 THEN 'Проверенная' ELSE 'Непроверенная' END
 , CASE WHEN M.DepartmentID = 2 THEN 'Sales Force' ELSE 'SMB' END
 , CASE WHEN ISNULL(NC.ContactURL,'') <> '' THEN 'С сайтом' ELSE 'Без сайта' END

UNION ALL

SELECT 'work.ua', HQ.CompanyID, HQ.CompanyName, HQ.IsApproved, HQ.LinkedNotebookID, HQ.IsLinked, HQ.SalesChannel, HQ.WebsiteExists, SUM(SC.VacancyCount)
FROM Analytics.dbo.SpiderCompany SC
 JOIN #SpiderCompanyHeadquarterCity HQ ON SC.CompanyID = HQ.CompanyID AND SC.Source = 1
WHERE HQ.CityID = @CityID
GROUP BY HQ.CompanyID, HQ.CompanyName, HQ.IsApproved, HQ.LinkedNotebookID, HQ.IsLinked, HQ.SalesChannel, HQ.WebsiteExists
HAVING SUM(SC.VacancyCount) > 0
)

SELECT CompanyID, CompanyName, LinkedNotebookID, WorkVacancyNum, RabotaVacancyNum
 , CASE 
    WHEN WorkVacancyNum < RabotaVacancyNum THEN 'У нас больше вакансий'
	WHEN WorkVacancyNum = RabotaVacancyNum THEN 'Одинаковое количество вакансий'
	WHEN RabotaVacancyNum = 0 THEN 'На ворке > 0, у нас 0'
	ELSE 'На ворке больше вакансий'
   END AS CompanyGroup
 , CASE 
    WHEN WorkVacancyNum < RabotaVacancyNum THEN 1
	WHEN WorkVacancyNum = RabotaVacancyNum THEN 2
	WHEN RabotaVacancyNum = 0 THEN 4
	ELSE 3
   END AS CompanyGroupOrdNum
 , CASE WHEN ContactAttempts > 0 THEN 'Была попытка контакта' ELSE 'Не было попытки контакта' END AS ContactGroup
FROM
(
SELECT 
  W.CompanyID, W.CompanyName, W.LinkedNotebookID, W.VacancyNum AS WorkVacancyNum
   , (SELECT COUNT(*) FROM Analytics.dbo.VacancyPublished WHERE NotebookID = W.LinkedNotebookID) AS RabotaVacancyNum
   , (SELECT COUNT(*) FROM Analytics.dbo.CRM_Action A WHERE A.NotebookID = W.LinkedNotebookID AND A.StateID = 2 AND A.TypeID = 1 AND CompleteDate >= DATEADD(DAY, -60, GETDATE())) AS ContactAttempts
FROM 
(
SELECT CompanyID, CompanyName, LinkedNotebookID, SUM(VacancyNum) AS VacancyNum
FROM C
WHERE Source = 'work.ua' AND IsLinked = 'Привязанная' AND SalesChannel = 'SMB'
GROUP BY CompanyID, CompanyName, LinkedNotebookID
) W
) T;

DROP TABLE #SpiderCompanyHeadquarterCity;