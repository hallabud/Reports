
CREATE PROCEDURE [dbo].[usp_ssrs_ReportDeviation] (@PublicationStartDate DATETIME)

AS

IF OBJECT_ID('tempdb..#ResponsesAttached','U') IS NOT NULL DROP TABLE #ResponsesAttached;
IF OBJECT_ID('tempdb..#ResponsesProf','U') IS NOT NULL DROP TABLE #ResponsesProf;
IF OBJECT_ID('tempdb..#ResponsesAll','U') IS NOT NULL DROP TABLE #ResponsesAll;
IF OBJECT_ID('tempdb..#ResponsesFinal','U') IS NOT NULL DROP TABLE #ResponsesFinal;
IF OBJECT_ID('tempdb..#Vacancies','U') IS NOT NULL DROP TABLE #Vacancies;
IF OBJECT_ID('tempdb..#VacsResponses','U') IS NOT NULL DROP TABLE #VacsResponses;
IF OBJECT_ID('tempdb..#AvgResponsesVacancies','U') IS NOT NULL DROP TABLE #AvgResponsesVacancies;
IF OBJECT_ID('tempdb..#MedianResponsesVacancies','U') IS NOT NULL DROP TABLE #MedianResponsesVacancies;
IF OBJECT_ID('tempdb..#StdevResponsesVacancies','U') IS NOT NULL DROP TABLE #StdevResponsesVacancies;
IF OBJECT_ID('tempdb..#DeviationResponses','U') IS NOT NULL DROP TABLE #DeviationResponses;
IF OBJECT_ID('tempdb..#FinalTable','U') IS NOT NULL DROP TABLE #FinalTable;

-- отклики аттачем
SELECT 
   VATV.OriginalVacancyID
 , CAST(COUNT(VATV.ID) AS DECIMAL(10,2)) AS 'ResponseCount'
INTO #ResponsesAttached
FROM SRV16.RabotaUA2.dbo.VacancyApplyToVacancy VATV          
WHERE 
 EXISTS (SELECT * 
		 FROM SRV16.RabotaUA2.dbo.VacancyStateHistory VSH 
		 WHERE VSH.State = 4 AND VSH.DateTo - VSH.DateFrom = 29 AND dbo.fnGetDatePart(VSH.DateTime) >= '2013-01-01' 
		  AND VSH.VacancyId = VATV.OriginalVacancyID AND VATV.AddDate BETWEEN VSH.DateTime AND VSH.DateTimeUpd)
GROUP BY VATV.OriginalVacancyID;

-- отклики резюме на сайте
SELECT
   RTV.OriginalVacancyID
 , CAST(COUNT(RTV.ID) AS DECIMAL(10,2)) AS 'ResponseCount'
INTO #ResponsesProf
FROM SRV16.RabotaUA2.dbo.ResumeToVacancy RTV
WHERE 
 EXISTS (SELECT * 
		 FROM SRV16.RabotaUA2.dbo.VacancyStateHistory VSH 
		 WHERE VSH.State = 4 AND VSH.DateTo - VSH.DateFrom = 29 AND dbo.fnGetDatePart(VSH.DateTime) >= '2013-01-01' 
		  AND VSH.VacancyId = RTV.OriginalVacancyID AND RTV.AddDate BETWEEN VSH.DateTime AND VSH.DateTimeUpd)
GROUP BY RTV.OriginalVacancyID;
 
-- общая таблица с откликами
SELECT * 
INTO #ResponsesAll
FROM #ResponsesAttached
UNION ALL
SELECT * 
FROM #ResponsesProf;

-- итоговая таблица с суммой откликов по каждой вакансии
SELECT OriginalVacancyID, SUM(ResponseCount) AS SumResponseCount
INTO #ResponsesFinal
FROM #ResponsesAll
GROUP BY OriginalVacancyID;

-- таблица с вакансиями, которые были непрерывно опубликованы в интересующем периоде
SELECT 
   VR.VacancyId
 , V.NotebookId
 , ISNULL(VE.AttractionLevel,0) AS AttractionLevel
 , R2.Name AS Rubric2Name 
INTO #Vacancies
FROM SRV16.RabotaUA2.dbo.VacancyStateHistory VSH 
 JOIN SRV16.RabotaUA2.dbo.VacancyRubricNEW VR ON VSH.VacancyId = VR.VacancyID AND VR.IsMain = 1
 JOIN SRV16.RabotaUA2.dbo.Rubric2Level R2 ON R2.Id = VR.RubricId2
 JOIN SRV16.RabotaUA2.dbo.VacancyExtra VE ON VE.VacancyId = VSH.VacancyId
 JOIN SRV16.RabotaUA2.dbo.Vacancy V ON VSH.VacancyId = V.Id
WHERE VSH.State = 4 
 AND VSH.DateTo - VSH.DateFrom = 29 
 AND dbo.fnGetDatePart(VSH.DateTime) >= '2013-01-01';

-- таблица с вакансиями + кол-во откликов по каждой вакансии
SELECT 
   V.VacancyID
 , V.NotebookId
 , AttractionLevel
 , Rubric2Name
 , ISNULL(SumResponseCount,0) AS ResponseCount
INTO #VacsResponses 
FROM #Vacancies V
 LEFT JOIN #ResponsesFinal FR ON V.VacancyId = FR.OriginalVacancyID;

-- средние кол-ва откликов на все вакансии для каждой подрубрики
SELECT Rubric2Name, AVG(ResponseCount) AS AvgResponseCount
INTO #AvgResponsesVacancies
FROM #VacsResponses
--WHERE AttractionLevel IN (4,5)
GROUP BY Rubric2Name;

-- мединана кол-ва откликов на все вакансии для каждой подрубрики
SELECT 
   Rubric2Name
 , AVG(ResponseCount) AS MedianResponseCount
INTO #MedianResponsesVacancies
FROM 
(  
SELECT * 
 , ROW_NUMBER() OVER (PARTITION BY Rubric2Name ORDER BY ResponseCount ASC, VacancyId ASC) AS RowAsc
 , ROW_NUMBER() OVER (PARTITION BY Rubric2Name ORDER BY ResponseCount DESC, VacancyId DESC) AS RowDesc
FROM #VacsResponses
--WHERE AttractionLevel IN (4,5)
) x
WHERE RowAsc IN (RowDesc, RowDesc - 1, RowDesc + 1)
GROUP BY Rubric2Name
ORDER BY Rubric2Name;

-- стандрартное отклонение кол-ва откликов по подрубрикам
SELECT Rubric2Name, STDEV(ResponseCount) AS StDeviation
INTO #StdevResponsesVacancies
FROM #VacsResponses
GROUP BY Rubric2Name;

-- таблица с вакансиями + кол-во откликов по каждой вакансии + отношения к медиане и среднему по подрубрике
SELECT 
   VR.VacancyID 
 , VR.NotebookId
 , VR.Rubric2Name
 , ResponseCount
 , AvgResponseCount
 , MedianResponseCount
 , CASE WHEN ISNULL(AvgResponseCount,0) <> 0 THEN ResponseCount / AvgResponseCount ELSE 0 END AS 'A'
 , CASE WHEN MedianResponseCount <> 0 THEN ResponseCount / MedianResponseCount ELSE 0 END AS 'B'
 , StDeviation
 , CASE WHEN ISNULL(StDeviation,0) <> 0 THEN (ResponseCount - AvgResponseCount) / StDeviation ELSE 0 END AS Diff
INTO #DeviationResponses
FROM #VacsResponses VR
 JOIN #AvgResponsesVacancies ARV ON VR.Rubric2Name = ARV.Rubric2Name
 JOIN #MedianResponsesVacancies MRV ON VR.Rubric2Name = MRV.Rubric2Name
 JOIN #StdevResponsesVacancies SRV ON VR.Rubric2Name = SRV.Rubric2name
WHERE StDeviation IS NOT NULL;

-- Финальная таблица
SELECT 
   Rubric2Name
 , StDeviation
 , AvgResponseCount
 , CASE
    WHEN Diff BETWEEN -1 AND 1 THEN 'от -1 до +1 сигмы'
    WHEN Diff BETWEEN 1 AND 2 THEN 'от +1 до +2 сигм'
    WHEN Diff > 2 THEN 'больше +2 сигм'
    WHEN Diff BETWEEN -2 AND -1 THEN 'от -2 до -1 сигмы' 
    WHEN Diff < -2 THEN 'меньше -2 сигм' 
   ELSE '***' END AS DiffRange
 , COUNT(DISTINCT NotebookId) AS NotebookCount
INTO #FinalTable
FROM #DeviationResponses
GROUP BY
   Rubric2Name
 , StDeviation
 , AvgResponseCount
 , CASE
    WHEN Diff BETWEEN -1 AND 1 THEN 'от -1 до +1 сигмы'
    WHEN Diff BETWEEN 1 AND 2 THEN 'от +1 до +2 сигм'
    WHEN Diff > 2 THEN 'больше +2 сигм'
    WHEN Diff BETWEEN -2 AND -1 THEN 'от -2 до -1 сигмы' 
    WHEN Diff < -2 THEN 'меньше -2 сигм' 
   ELSE '***' END;

SELECT 
   Rubric2Name
 , StDeviation
 , AvgResponseCount
 , ISNULL([от -1 до +1 сигмы],0) AS 'от -1 до +1 сигмы'
 , ISNULL([от +1 до +2 сигм],0) AS 'от +1 до +2 сигм'
 , ISNULL([больше +2 сигм],0) AS 'больше +2 сигм'
 , ISNULL([от -2 до -1 сигмы],0) AS 'от -2 до -1 сигмы' 
 , ISNULL([меньше -2 сигм],0) AS 'меньше -2 сигм'
FROM 
(SELECT Rubric2Name, StDeviation, AvgResponseCount, DiffRange, NotebookCount
FROM #FinalTable) p
PIVOT
(
SUM(NotebookCount)
FOR DiffRange IN ([от -1 до +1 сигмы],[от +1 до +2 сигм],[больше +2 сигм],[от -2 до -1 сигмы],[меньше -2 сигм])
) AS pvt
ORDER BY Rubric2Name

--+посчитать среднее число откликов по вакансиям с хорошим качеством (качество 4 или 5) в каждой подрубрике - X
--+посчитать медиану откликов с хор. качеством в каждой подрубрике - Y
--+посчитать количество откликов для каждой вакансии независимо от качества
--+для каждой вакансии посчитать отношение кол-ва откликов к X и к Y записав значения в переменные A и B соответственно
--посчитать стандартное отклонение сигма для множества кол-ва откликов по вакансиям

--разбить вакансии на сегменты по значению A:
--выше среднего
--в пределах одной сигмы
--в пределах 2-х сигм
--ниже среднего
--ниже одной сигмы
--ниже двух сигм
--сформировать отчет по распределению компаний по сегментам
--формат: радиальная диаграмма с отображением процента и кол-ва компаний по каждому из сегментов

DROP TABLE #ResponsesAttached;
DROP TABLE #ResponsesProf;
DROP TABLE #ResponsesAll;
DROP TABLE #ResponsesFinal;
DROP TABLE #Vacancies;
DROP TABLE #VacsResponses;
DROP TABLE #AvgResponsesVacancies;
DROP TABLE #MedianResponsesVacancies;
DROP TABLE #StdevResponsesVacancies;
DROP TABLE #DeviationResponses;
DROP TABLE #FinalTable;