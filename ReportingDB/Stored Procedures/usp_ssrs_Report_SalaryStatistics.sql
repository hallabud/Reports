CREATE PROCEDURE dbo.usp_ssrs_Report_SalaryStatistics

AS 

WITH C AS
 (
SELECT FS.SalarySource, DD.YearNum, DD.QuarterNum, DR.RubricId1, DR.RubricId2, CityId, ProfLevelId
 , COUNT(ItemID) AS ItemsCount, dbo.BottomQuartile(Salary) AS QuartileBottom, dbo.Median(Salary) AS Median, dbo.TopQuartile(Salary) AS QuartileTop, AVG(Salary) AS AvgSalary
FROM dbo.FactSalaries FS
 JOIN dbo.DimDate DD ON FS.Date_key = DD.Date_key
 JOIN dbo.DimRubrics DR ON FS.RubricID = DR.RubricID
GROUP BY GROUPING SETS 
  (
   (SalarySource, DD.YearNum, DD.QuarterNum, RubricId1, RubricId2, CityId, ProfLevelId),
   
   (SalarySource, DD.YearNum),
   
   (SalarySource, DD.YearNum, DD.QuarterNum),
   (SalarySource, DD.YearNum, RubricId1),
   (SalarySource, DD.YearNum, CityId),
   (SalarySource, DD.YearNum, ProfLevelId),
   
   (SalarySource, DD.YearNum, DD.QuarterNum, RubricId1),
   (SalarySource, DD.YearNum, DD.QuarterNum, CityId),
   (SalarySource, DD.YearNum, DD.QuarterNum, ProfLevelId),
   (SalarySource, DD.YearNum, RubricId1, RubricId2),
   (SalarySource, DD.YearNum, RubricId1, CityId),
   (SalarySource, DD.YearNum, RubricId1, ProfLevelId),
   (SalarySource, DD.YearNum, CityId, ProfLevelId),
   
   (SalarySource, DD.YearNum, DD.QuarterNum, RubricId1, RubricId2),
   (SalarySource, DD.YearNum, DD.QuarterNum, RubricId1, CityId),
   (SalarySource, DD.YearNum, DD.QuarterNum, RubricId1, ProfLevelId),
   (SalarySource, DD.YearNum, DD.QuarterNum, CityId, ProfLevelId),
   (SalarySource, DD.YearNum, RubricId1, RubricId2, CityId),
   (SalarySource, DD.YearNum, RubricId1, RubricId2, ProfLevelId),
   (SalarySource, DD.YearNum, RubricId1, CityId, ProfLevelId),
   
   (SalarySource, DD.YearNum, DD.QuarterNum, RubricId1, RubricId2, CityId),
   (SalarySource, DD.YearNum, DD.QuarterNum, RubricId1, RubricId2, ProfLevelId)
  )
 )
SELECT 
   DSS.Name AS SalarySource
 , YearNum
 , ISNULL(QuarterNum, 0) AS QuarterNum
 , CASE WHEN QuarterNum IS NULL THEN 'Все кварталы' ELSE 'Q' + CAST(QuarterNum AS VARCHAR) END AS QuarterName
 , ISNULL(C.RubricId1, 0) AS RubricId1
 , CASE WHEN C.RubricId1 IS NULL THEN 'Все рубрики' ELSE R1.Rubric1 END AS Rubric1
 , ISNULL(C.RubricId2, 0) AS RubricId2
 , CASE WHEN C.RubricId2 IS NULL THEN 'Все подрубрики' ELSE DR.Rubric2 END AS Rubric2
 , ISNULL(CityId, 0) AS CityId
 , CASE WHEN C.CityId IS NULL THEN 'Все регионы' ELSE DC.Name END AS City
 , ISNULL(ProfLevelId, 0) AS ProfLevelID
 , CASE WHEN C.ProfLevelId IS NULL THEN 'Все уровни должности' ELSE DPL.Name END AS ProfLevel
 , ItemsCount
 , QuartileBottom
 , Median
 , QuartileTop
 , AvgSalary
FROM C
 JOIN dbo.DimSalarySource DSS ON C.SalarySource = DSS.Id
 LEFT JOIN dbo.DimRubrics DR ON C.RubricId1 = DR.RubricId1 AND C.RubricId2 = DR.RubricId2
 LEFT JOIN dbo.DimCity DC ON C.CityId = DC.Id
 LEFT JOIN dbo.DimProfLevel DPL ON C.ProfLevelId = DPL.Id
 LEFT JOIN (SELECT DISTINCT RubricId1, Rubric1 FROM dbo.DimRubrics) R1 ON C.RubricId1 = R1.RubricId1
ORDER BY SalarySource, YearNum, QuarterNum, RubricId1, RubricId2, CityId, ProfLevelId;