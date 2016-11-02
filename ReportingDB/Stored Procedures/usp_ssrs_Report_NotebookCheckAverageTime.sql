
CREATE PROCEDURE [dbo].[usp_ssrs_Report_NotebookCheckAverageTime] 
	@StartDate DATETIME,
	@EndDate DATETIME

AS

SET DATEFIRST 1;

WITH Operators AS
 (
SELECT 'AlexeyT@rabota.ua' AS LoginEmail, 'Алексей Цилинский' AS OperatorName
UNION ALL
SELECT 'AnnaKr@rabota.ua', 'Анна Кравченко'
UNION ALL
SELECT 'InnaM@rabota.ua', 'Инна Мельниченко'
UNION ALL
SELECT 'YuraK@rabota.ua' AS LoginEmail, 'Юрий Ковалев' AS OperatorName
UNION ALL
SELECT 'JuliaP@rabota.ua', 'Юлия Пичугина'
UNION ALL
SELECT 'AllaU@rabota.ua', 'Alla Ustimenko'
UNION ALL
SELECT 'AnnaB@rabota.ua', 'Anna Bondar'
UNION ALL
SELECT 'AnnaT@rabota.ua', 'Anna Tkachuk'
UNION ALL
SELECT 'DenisM@rabota.ua', 'Denis Martich'
UNION ALL
SELECT 'InnaM@rabota.ua', 'Inna Melnichenko'
UNION ALL
SELECT 'LyubovD@rabota.ua', 'Lyubov Davidyuk'
UNION ALL
SELECT 'YuliyaK@rabota.ua', 'Yuliya Kostyuk' 
UNION ALL
SELECT 'ZlataM@rabota.ua', 'Zlata Mitskevich'
 )
 , C_Log AS
 (
-- Подтверждение емейла
SELECT 'Email Confirmation' AS ActionType
 , LogID
 , NotebookID
 , LoginEmail
 , ValInt
 , AddDate
FROM Analytics.dbo.NotebookCompany_Log NCL
WHERE EventID = 1 
 AND AddDate BETWEEN @StartDate AND @EndDate
 AND ValInt NOT IN (5,7) 
 AND EXISTS (SELECT * FROM Analytics.dbo.NotebookCompany_Log WHERE NotebookID = NCL.NotebookID AND EventID IN (2, 3, 4, 11) AND AddDate BETWEEN @StartDate AND @EndDate AND AddDate >= NCL.AddDate)

UNION ALL

-- Кнопка "Одобрить"
SELECT 'Активировано'
 , LogID
 , NotebookID
 , LoginEmail 
 , ValInt
 , AddDate
FROM Analytics.dbo.NotebookCompany_Log NCL
WHERE EventID = 2 
 AND PageID = 1 
 AND ValInt IN (5,7) 
 AND AddDate BETWEEN @StartDate AND @EndDate
 AND EXISTS (SELECT * FROM Analytics.dbo.NotebookCompany_Log WHERE NotebookID = NCL.NotebookID AND EventID IN (1) AND AddDate BETWEEN @StartDate AND @EndDate AND AddDate <= NCL.AddDate)

UNION ALL

-- Кнопка "Отправить на профиль"
SELECT 'Активировано'
 , LogID
 , NotebookID
 , LoginEmail 
 , ValInt
 , AddDate
FROM Analytics.dbo.NotebookCompany_Log NCL
WHERE EventID = 11
 AND PageID = 1
 AND ValInt IN (5,7)
 AND AddDate BETWEEN @StartDate AND @EndDate
 AND EXISTS (SELECT * FROM Analytics.dbo.NotebookCompany_Log WHERE NotebookID = NCL.NotebookID AND EventID IN (1) AND AddDate BETWEEN @StartDate AND @EndDate AND AddDate <= NCL.AddDate)

UNION ALL

-- Кнопка "Отказать"
SELECT 'Отказано'
 , LogID
 , NotebookID
 , LoginEmail 
 , ValInt
 , AddDate
FROM Analytics.dbo.NotebookCompany_Log NCL
WHERE EventID = 3
 AND PageID = 1
 AND ValInt NOT IN (5,7)
 AND ValStr IS NOT NULL
 AND AddDate BETWEEN @StartDate AND @EndDate
 AND EXISTS (SELECT * FROM Analytics.dbo.NotebookCompany_Log WHERE NotebookID = NCL.NotebookID AND EventID IN (1) AND AddDate BETWEEN @StartDate AND @EndDate AND AddDate <= NCL.AddDate)

UNION ALL

-- Кнопка "Черный список"
SELECT 'Черный список' 
 , LogID
 , NotebookID
 , LoginEmail 
 , ValInt
 , AddDate
FROM Analytics.dbo.NotebookCompany_Log NCL
WHERE EventID = 4
 AND PageID = 1
 AND AddDate BETWEEN @StartDate AND @EndDate
 AND EXISTS (SELECT * FROM Analytics.dbo.NotebookCompany_Log WHERE NotebookID = NCL.NotebookID AND EventID IN (1) AND AddDate BETWEEN @StartDate AND @EndDate AND AddDate <= NCL.AddDate)
 AND NOT EXISTS (SELECT * FROM Analytics.dbo.NotebookCompany_Log WHERE NotebookID = NCL.NotebookID AND EventID IN (3) AND AddDate <= NCL.AddDate)
 )
 , C_LogGrp AS
 (
SELECT ActionType, NotebookID, LoginEmail, MIN(AddDate) AS AddDate
FROM C_Log
GROUP BY ActionType, NotebookID, LoginEmail
 )
 , C_List AS
 (
SELECT 
   CASE 
    WHEN DATEPART(HOUR, AddDate) BETWEEN 9 AND 17 AND DATEPART(WEEKDAY, AddDate) BETWEEN 1 AND 5 THEN 'Рабочее время' 
	ELSE 'Нерабочее время'
   END AS DayWorkingTimePart
 , *
FROM C_LogGrp
 )

SELECT L1.DayWorkingTimePart, dbo.fnGetDatePart(L1.AddDate) AS FullDate, DD.YearNum, DD.WeekNum, DD.WeekName, L2.ActionType, O.OperatorName, DATEDIFF(MINUTE, L1.AddDate, L2.AddDate) AS Duration, L1.NotebookID
FROM C_List L1
 JOIN C_List L2 ON L1.NotebookID = L2.NotebookID AND L1.AddDate < L2.AddDate
 JOIN Operators O ON L2.LoginEmail = O.LoginEmail
 JOIN dbo.DimDate DD ON dbo.fnGetDatePart(L1.AddDate) = DD.FullDate
WHERE L1.ActionType = 'Email Confirmation';