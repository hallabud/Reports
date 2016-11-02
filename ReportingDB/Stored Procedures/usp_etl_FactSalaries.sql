CREATE PROCEDURE [dbo].[usp_etl_FactSalaries]

AS

DECLARE @Rate DECIMAL(7,2) = (SELECT Rate FROM Analytics.dbo.Currency WHERE Id = 1);
DECLARE @DateKey INT = (SELECT Date_key FROM Reporting.dbo.DimDate WHERE FullDate = CAST(GETDATE() AS DATE))

INSERT INTO dbo.FactSalaries (SalarySource, ItemID, Date_key, RubricID, CityId, ProfLevelId, Salary)
SELECT 
   2 AS SalarySource
 , VP.ID
 , @DateKey
 , DR.RubricID
 , CASE COALESCE(C.OblastCityId, C.Id) 
    WHEN 29 THEN 12
	WHEN 28 THEN 8
	ELSE COALESCE(C.OblastCityId, C.Id) 
   END AS CityId
 , VP.ProfLevelID
 , VP.Salary
FROM Analytics.dbo.VacancyPublished VP
 JOIN Analytics.dbo.VacancyRubricNEW VRN ON VP.Id = VRN.VacancyId
 JOIN Analytics.dbo.Rubric1To2 R12 ON VRN.RubricId2 = R12.RubricId2
 JOIN Analytics.dbo.VacancyCity VC ON VP.Id = VC.VacancyId
 JOIN Analytics.dbo.City C ON VC.CityId = C.Id
 JOIN Analytics.dbo.ProfLevel PL ON VP.ProfLevelID = PL.ID
 JOIN Reporting.dbo.DimRubrics DR ON R12.RubricId1 = DR.RubricId1 AND R12.RubricId2 = DR.RubricId2
WHERE VP.Salary BETWEEN 1000 AND 200000
 AND VP.UpdateDate BETWEEN dbo.fnGetDatePart(GETDATE() - 1) AND dbo.fnGetDatePart(GETDATE());

INSERT INTO dbo.FactSalaries (SalarySource, ItemID, Date_key, RubricID, CityId, ProfLevelId, Salary)
SELECT
   1 AS SalarySource
 , R.ID
 , @DateKey
 , DR.RubricID
 , CASE COALESCE(C.OblastCityId, C.Id) 
    WHEN 29 THEN 12
	WHEN 28 THEN 8
	ELSE COALESCE(C.OblastCityId, C.Id) 
   END AS CityId
 , R.ProfLevelID
 , CASE WHEN R.CurrencyId = 2 THEN R.Salary * @Rate ELSE R.Salary END AS Salary
FROM Analytics.dbo.Resume R
 JOIN Analytics.dbo.ResumeRubricNEW RRN ON R.Id = RRN.ResumeId
 JOIN Analytics.dbo.Rubric1To2 R12 ON RRN.RubricId2 = R12.RubricId2
 JOIN Analytics.dbo.City C ON R.CityId = C.Id
 JOIN Analytics.dbo.ProfLevel PL ON R.ProfLevelID = PL.ID
 JOIN Reporting.dbo.DimRubrics DR ON R12.RubricId1 = DR.RubricId1 AND R12.RubricId2 = DR.RubricId2
WHERE R.State = 1
 AND CASE WHEN R.CurrencyId = 2 THEN R.Salary * @Rate ELSE R.Salary END BETWEEN 1000 AND 200000
 AND R.UpdateDate BETWEEN dbo.fnGetDatePart(GETDATE() - 1) AND dbo.fnGetDatePart(GETDATE());





