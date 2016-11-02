
CREATE PROCEDURE [dbo].[usp_ssrs_ReportCategorizationVacancyRubrics]
 (@StartDate DATETIME, @EndDate DATETIME)

AS

SET DATEFIRST 1;
SET @EndDate = DATEADD(DAY, 1, @EndDate);

SELECT
   VE.ModeratedRubricLastDate
 , VE.ModeratedRubricLastLogin
 , VE.VacancyID
 , V.Name AS 'VacancyName'
 , (SELECT TOP 1 R1.Name 
    FROM Analytics.dbo.Rubric1Level R1
     JOIN Analytics.dbo.Rubric1To2 R12 ON R1.Id = R12.RubricId1
     JOIN Analytics.dbo.VacancyRubricNEW VRN ON R12.RubricId2 = VRN.RubricId2
    WHERE VRN.IsMain = 1 AND VRN.VacancyId = VE.VacancyID) AS 'RubricName'
 , CASE 
    WHEN DATEPART(WEEKDAY, VE.ModeratedRubricLastDate) NOT IN (6,7) AND DATEPART(HOUR,VE.ModeratedRubricLastDate) BETWEEN 9 AND 18 
     THEN 1
    ELSE 0
   END AS IsWorkingTime
FROM Analytics.dbo.VacancyExtra VE
 JOIN Analytics.dbo.Vacancy V ON VE.VacancyID = V.Id
WHERE VE.ModeratedRubricLastDate BETWEEN @StartDate AND @EndDate;