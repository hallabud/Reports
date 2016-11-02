CREATE PROCEDURE [dbo].[usp_ssrs_Report_CrmJobProgramsRegions] 
 (@StartDate DATETIME, @EndDate DATETIME)

AS

-- Общий пул по регионам
WITH C_Total AS
 ( 
SELECT DISTINCT YearNum, MonthNum, CityId, CityName, NotebookID
FROM 
(
-- Активные 6
SELECT A6.YearNum, A6.MonthNum, C.Id AS CityId, C.Name AS CityName, A6.NotebookId
FROM Reporting.dbo.vw_CompaniesActivityGroups_Active6 A6
 JOIN Analytics.dbo.NotebookCompany NC ON A6.NotebookID = NC.NotebookID
 JOIN Analytics.dbo.City C ON NC.HeadquarterCityID = C.ID 
WHERE A6.FullDate BETWEEN @StartDate AND @EndDate
UNION ALL
-- + новые регистрации
SELECT DATEPART(YEAR, NC.AddDate), DATEPART(MONTH, NC.AddDate), HeadquarterCityID, C.Name, NC.NotebookID
FROM Analytics.dbo.NotebookCompany NC
 JOIN Analytics.dbo.City C ON NC.HeadquarterCityId = C.ID
WHERE NC.AddDate BETWEEN @StartDate AND @EndDate + 1
) t
--GROUP BY YearNum, MonthNum, CityId, CityName
 )
 , C_Result AS
 (
SELECT * 
 , CASE 
    WHEN EXISTS (SELECT * 
				 FROM Analytics.dbo.CRM_JobProgram_NotebookLog NL 
				 WHERE NL.NotebookID = C.NotebookID AND DATEPART(YEAR, NL.AddDate) = C.YearNum AND DATEPART(MONTH, NL.AddDate) = C.MonthNum
				  AND NL.JobProgramID IN (4,6,7,10,13,16)) THEN 'Попавшие в выборку'
    ELSE 'Не попавшие в выборку' 
   END AS 'WasInQueryResult'
 , CASE 
    WHEN EXISTS (SELECT *
				 FROM Analytics.dbo.CRM_Action A
				  JOIN Analytics.dbo.CRM_JobProgram_Question Q ON Q.JobProgramID = A.JobProgramID
				  JOIN Analytics.dbo.CRM_JobProgram_Question_Answer Aw ON Aw.QuestionID = Q.ID
				 WHERE A.NotebookID = C.NotebookId AND DATEPART(YEAR, A.CompleteDate) = C.YearNum AND DATEPART(MONTH, A.CompleteDate) = C.MonthNum 
				  AND A.TypeID = 1 AND A.StateID = 2 AND Aw.Name NOT LIKE '%дозвон%' AND A.JobProgramID IN (4,6,7,10,13,16)) THEN 'Есть контакт'
	ELSE 'Нет контакта'
   END AS 'WasSuccessfulContact'
 , CASE
    WHEN EXISTS (SELECT * 
				 FROM Analytics.dbo.NotebookCompany_Spent NCS
				 WHERE NCS.NotebookID = C.NotebookId 
				  AND DATEPART(YEAR, NCS.AddDate) = C.YearNum AND DATEPART(MONTH, NCS.AddDate) = C.MonthNum) THEN 'Есть вакансия'
    ELSE 'Нет вакансии'
   END AS 'HasVacancy'
FROM C_Total C
 )

SELECT YearNum
 , MonthNum
 , CASE MonthNum
    WHEN 1 THEN 'Январь'
	WHEN 2 THEN 'Февраль'
	WHEN 3 THEN 'Март'
	WHEN 4 THEN 'Апрель'
	WHEN 5 THEN 'Май'
	WHEN 6 THEN 'Июнь'
	WHEN 7 THEN 'Июль'
	WHEN 8 THEN 'Август'
	WHEN 9 THEN 'Сентябрь'
	WHEN 10 THEN 'Октябрь'
	WHEN 11 THEN 'Ноябрь'
	WHEN 12 THEN 'Декабрь'
   END AS MonthNameRus
 , CityName, WasInQueryResult, WasSuccessfulContact, HasVacancy, COUNT(*) AS CompanyNum
FROM C_Result
GROUP BY YearNum, MonthNum
 , CASE MonthNum
    WHEN 1 THEN 'Январь'
	WHEN 2 THEN 'Февраль'
	WHEN 3 THEN 'Март'
	WHEN 4 THEN 'Апрель'
	WHEN 5 THEN 'Май'
	WHEN 6 THEN 'Июнь'
	WHEN 7 THEN 'Июль'
	WHEN 8 THEN 'Август'
	WHEN 9 THEN 'Сентябрь'
	WHEN 10 THEN 'Октябрь'
	WHEN 11 THEN 'Ноябрь'
	WHEN 12 THEN 'Декабрь'
   END
 , CityName, WasInQueryResult, WasSuccessfulContact, HasVacancy;