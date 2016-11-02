
CREATE PROCEDURE dbo.usp_ssrs_Report_VacancyCheckAverageTime
   @StartDate DATE
 , @EndDate DATE

AS

-- -------------------------------------------------
-- Варим кашу из топора...
-- Сваливаем из разных таблиц всё в одну времянку
-- -------------------------------------------------
-- Сознательно отсекаем все нетипичные случаи
-- Оставляем только те случаи, где есть факты и публикации, и модерации, и категоризации в рамках анализируемого периода
-- Исключаем случаи, когда категоризация была раньше модерации
-- Исключаем случаи с повторными публикациями
-- Исключаем случаи где были возвраты на можерацию, блокировки и т.п.
-- Берем только случаи, когда факты публикации/можерации/категоризации состоялись в рамках одного-двух дней
-- -------------------------------------------------

SET DATEFIRST 1

IF OBJECT_ID('tempdb..#Log','U') IS NOT NULL DROP TABLE #Log;
IF OBJECT_ID('tempdb..#T','U') IS NOT NULL DROP TABLE #T;

WITH C AS
 (
SELECT VacancyID, LoginEMail, AddDate, 'Модерация' AS ActionType
FROM Analytics.dbo.ModeratedHistory MH
WHERE MH.Type = 1
 AND MH.VacancyID IS NOT NULL
 AND MH.AddDate BETWEEN @StartDate AND @EndDate
 AND EXISTS (SELECT * FROM Analytics.dbo.VacancyMultiUserHistory WHERE VacancyID = MH.VacancyID AND MultiUserHistoryTypeID = 23 AND AddDate BETWEEN @StartDate AND @EndDate) 
 AND EXISTS (SELECT * FROM Analytics.dbo. VacancyMultiUserHistory WHERE VacancyID = MH.VacancyID AND MultiUserHistoryTypeID = 2 AND AddDate BETWEEN @StartDate AND @EndDate) 
 
UNION ALL

SELECT VacancyID, LoginEmail, AddDate, 'Публикация' AS ActionType
FROM Analytics.dbo.VacancyMultiUserHistory H
WHERE H.MultiUserHistoryTypeID = 2
 AND LoginEMail <> 'AUTOREPUBLISH'
 AND H.AddDate BETWEEN @StartDate AND @EndDate
 AND EXISTS (SELECT * FROM Analytics.dbo.VacancyMultiUserHistory WHERE VacancyID = H.VacancyID AND MultiUserHistoryTypeID = 23 AND AddDate BETWEEN @StartDate AND @EndDate)
 AND EXISTS (SELECT * FROM Analytics.dbo.ModeratedHistory WHERE VacancyID = H.VacancyID AND Type = 1 AND AddDate BETWEEN @StartDate AND @EndDate)

UNION ALL

SELECT DISTINCT VacancyID, LoginEmail, AddDate, 'Категоризация' AS ActionType
FROM Analytics.dbo.VacancyMultiUserHistory H
WHERE H.MultiUserHistoryTypeID = 23
 AND H.AddDate BETWEEN @StartDate AND @EndDate
 AND EXISTS (SELECT * FROM Analytics.dbo.VacancyMultiUserHistory WHERE VacancyID = H.VacancyID AND MultiUserHistoryTypeID = 2 AND AddDate BETWEEN @StartDate AND @EndDate)
 AND EXISTS (SELECT * FROM Analytics.dbo.ModeratedHistory WHERE VacancyID = H.VacancyID AND Type = 1 AND AddDate BETWEEN @StartDate AND @EndDate)
 )

SELECT *, ROW_NUMBER() OVER(PARTITION BY VacancyID ORDER BY AddDate) AS RowNum
INTO #Log
FROM C;

SELECT VacancyID, Pbl.AddDate AS PublicationDT
 , (SELECT MIN(AddDate) FROM #Log AS Mdr WHERE Mdr.ActionType = 'Модерация' AND Mdr.VacancyID = Pbl.VacancyID AND Mdr.RowNum > Pbl.RowNum) AS ModerationDT
 , (SELECT MIN(AddDate) FROM #Log AS Ctg WHERE Ctg.ActionType = 'Категоризация' AND Ctg.VacancyID = Pbl.VacancyID AND Ctg.RowNum > Pbl.RowNum) AS CategorizationDT
INTO #T
FROM #Log AS Pbl
WHERE ActionType = 'Публикация'
 AND NOT EXISTS (SELECT * FROM Analytics.dbo.BlockingHistory WHERE VacancyID = Pbl.VacancyID AND AddDate >= Pbl.AddDate)
 AND NOT EXISTS (SELECT * FROM #Log WHERE ActionType = 'Публикация' AND VacancyID = Pbl.VacancyID AND RowNum > Pbl.RowNum);

SELECT 
   Reporting.dbo.fnGetDatePart(PublicationDT) AS FullDate
 , CASE 
    WHEN DATEPART(HOUR, PublicationDT) BETWEEN 9 AND 17 AND DATEPART(WEEKDAY, PublicationDT) BETWEEN 1 AND 5 THEN 'Рабочее время' 
	ELSE 'Нерабочее время'
   END AS DayWorkingTimePart
 , AVG(DATEDIFF(MINUTE, PublicationDT, ModerationDT)) AS DurationMinModeration
 , AVG(DATEDIFF(MINUTE, ModerationDT, CategorizationDT)) AS DurationMinCategorization
FROM #T
WHERE ModerationDT IS NOT NULL 
 AND CategorizationDT IS NOT NULL
 AND DATEDIFF(MINUTE, ModerationDT, CategorizationDT) > 0
 AND DATEDIFF(DAY, PublicationDT, ModerationDT) <= 1
GROUP BY
   Reporting.dbo.fnGetDatePart(PublicationDT) 
 , CASE 
    WHEN DATEPART(HOUR, PublicationDT) BETWEEN 9 AND 17 AND DATEPART(WEEKDAY, PublicationDT) BETWEEN 1 AND 5 THEN 'Рабочее время' 
	ELSE 'Нерабочее время'
   END
 ORDER BY FullDate, DayWorkingTimePart;

DROP TABLE #Log;
DROP TABLE #T;