
--EXEC dbo.usp_ssrs_ReportBenchmarkingCompanyRating 
-- @StartDate = '20130101', @EndDate = '20130301'

CREATE PROCEDURE [dbo].[usp_ssrs_ReportBenchmarkingCompanyRating]
 @StartDate AS DATETIME,
 @EndDate AS DATETIME

AS

WITH CTE_WorkMaxIDs AS
 (
SELECT 
   WeekLastDate
 , (SELECT MaxID 
	FROM SRV16.RabotaUA2.dbo.WorkVacancyResumeCount 
	WHERE Type = 1 AND [Date] = DATEADD(DAY,-7,t1.[Date])) AS PreviousWeekMaxId
 , MaxId
FROM 
  (
  SELECT 
   [Date]
   , DATEADD(DAY,-1,[Date]) AS WeekLastDate
   , MaxID 
  FROM 
   SRV16.RabotaUA2.dbo.WorkVacancyResumeCount
  WHERE [Type] = 1
  ) AS t1
 )
, SV_Flags AS
 (
SELECT 
   dbo.fnGetDatePart(SV.AddDate) AS 'VacancyAddDate'
 , 'work.ua' AS 'SourceName'
 , CASE 
    WHEN SC.Rating > 2 THEN CAST(SC.Rating AS VARCHAR)
    ELSE 'ND' 
   END AS 'CompanyRating'
 , SV.SpiderVacancyID AS 'VacancyID'
FROM SRV16.RabotaUA2.dbo.SpiderVacancy SV
 JOIN SRV16.RabotaUA2.dbo.SpiderCompany SC
  ON SV.SpiderCompanyID = SC.CompanyId AND SV.Source = SC.Source
WHERE SV.Source = 1
 AND SV.AddDate >= '20130218'
 AND SV.AddDate BETWEEN @StartDate AND @EndDate
UNION ALL
SELECT
   dbo.fnGetDatePart(V.AddDate)
 , 'rabota.ua'
 , CASE 
    WHEN NC.Rating > 2 THEN CAST(NC.Rating AS VARCHAR)
    ELSE 'ND' 
   END
 , V.Id
FROM SRV16.RabotaUA2.dbo.Vacancy V
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC
  ON V.NotebookId = NC.NotebookId
 JOIN 
(SELECT VacancyId, MIN(CityId) AS MinCityId
 FROM SRV16.RabotaUA2.dbo.VacancyCity
 GROUP BY VacancyId) AS VCity
  ON V.Id = VCity.VacancyId
WHERE 
 EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 1)
 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.ModeratedHistory MH WHERE MH.VacancyId = V.Id AND MH.Type = 2)
 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.VacancyPublishHistory WHERE VacancyId = V.Id)
 AND NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.VacancyStateHistory 
				  WHERE VacancyId = V.Id AND [State] = 3 
				   AND DATEPART(YEAR,[DateTime]) = DATEPART(YEAR,V.AddDate)
                   AND DATEPART(WEEK,[DateTime]) = DATEPART(WEEK,V.AddDate))
 AND V.AddDate >= '20130218'
 AND V.AddDate BETWEEN @StartDate AND @EndDate
UNION ALL
SELECT
   dbo.fnGetDatePart(VD.AddDate)
 , 'rabota.ua'
 , CASE 
    WHEN NC.Rating > 2 THEN CAST(NC.Rating AS VARCHAR)
    ELSE 'ND' 
   END
 , VD.VacancyID
FROM SRV16.RabotaUA2.dbo.Vacancy_Deleted VD
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC
  ON VD.NotebookId = NC.NotebookId
WHERE VD.Was_IsModerated = 1 AND VD.Was_IsModeratedRubric = 1
 AND EXISTS(SELECT * FROM SRV16.RabotaUA2.dbo.VacancyPublishHistory WHERE VacancyId = VD.VacancyId)
 AND VD.AddDate >= '20130218'
 AND VD.AddDate BETWEEN @StartDate AND @EndDate
 )
, Vacancies_Comparsion AS
 (
SELECT 
   YearNum
 , WeekNum
 , WeekName
 , LastWeekDate
 , CompanyRating
 , [rabota.ua] AS 'rabota.ua'
 , [work.ua] AS 'work.ua'
FROM 
(
SELECT 
    DD.YearNum
  , DD.WeekNum
  , DD.WeekName
  , DD.LastWeekDate
  , SourceName
  , CompanyRating
  , VacancyID
 FROM SV_Flags SVF
  JOIN Reporting.dbo.DimDate DD
   ON SVF.VacancyAddDate = DD.FullDate
  LEFT JOIN CTE_WorkMaxIDs WMI
   ON DD.LastWeekDate = WMI.WeekLastDate AND SourceName = 'work.ua'
 WHERE MaxId IS NULL OR VacancyID BETWEEN PreviousWeekMaxId AND MaxId
) p
PIVOT
(
COUNT(VacancyID)
FOR SourceName IN ([rabota.ua],[work.ua])
) AS pvt
 )
SELECT 
   YearNum
 , WeekNum
 , WeekName
 , LastWeekDate
 , CompanyRating
 , [rabota.ua] AS 'rabota.ua'
 , [work.ua] AS 'work.ua'
 , CASE 
    WHEN dbo.fnGetMinimumOf2Values([rabota.ua],[work.ua]) = 0 THEN NULL
    ELSE CAST(1.0 * ([rabota.ua] - [work.ua]) / dbo.fnGetMinimumOf2Values([rabota.ua],[work.ua]) AS decimal(8,4))
   END  AS 'GAP'
FROM Vacancies_Comparsion;