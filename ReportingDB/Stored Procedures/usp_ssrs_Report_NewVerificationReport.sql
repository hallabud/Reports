

-- ========================================================================================================
-- Author:		GranovskaA <AnastasiyaG@rabota.ua>
-- Create date: 2016-10-25
-- ========================================================================================================
-- Description:	Входящие параметры процедуры
--				@StartDate - начальная дата
--				@EndDate - конечная дата
--Данные по платежам для отчета	New Verification report
--EXECUTE [usp_ssrs_Report_NewVerificationReport] @StartDate ='2016-10-01', @EndDate='2016-10-25'	
-- ========================================================================================================

CREATE PROCEDURE [dbo].[usp_ssrs_Report_NewVerificationReport]
 @StartDate DATETIME, @EndDate DATETIME

AS

-- -------------------------------------------------
--для тестирования: вместо входящих параметров процедуры
--DECLARE @StartDate DATETIME
--DECLARE @EndDate DATETIME
--set @StartDate = '2016-10-23';
--set @EndDate   = '2016-10-25';

WITH C AS
 (
SELECT 
   DD.FullDate
 , DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.WeekNum
 , DD.WeekName
 , CASE NCL.LoginEmail
   	WHEN 'Annakr@rabota.ua' THEN 'Кравченко Анна'
	WHEN 'NataliyaM@rabota.ua' THEN 'Манжула Наталья'
	WHEN 'Evgeniyak@rabota.ua' THEN 'Коротич Евгения'
	WHEN 'juliap@rabota.ua' THEN 'Пичугина Юлия'
	WHEN 'YuraK@rabota.ua' THEN 'Ковалев Юрий'
	ELSE NCL.LoginEmail
   END AS Verificator
  , CASE NCL.EventID 
     WHEN 2 THEN 'Одобрить'
	 WHEN 3 THEN 'Отказать'
	 WHEN 4 THEN 'Черный список'
	 WHEN 11 THEN 'Отправить на профиль'
	 ELSE CAST(NCL.EventID AS VARCHAR)
	END AS Event
  , NCL.NotebookID
  , CASE 
     WHEN NCL.EventID = 11 THEN COALESCE(NS_Mrg.Name, NS_Cur.Name)
	 ELSE COALESCE(NS_Mrg.Name, NS_Log.Name)
	END AS NotebookState
FROM SRV16.RabotaUA2.dbo.NotebookCompany_Log NCL WITH (NOLOCK)
 JOIN Reporting.dbo.DimDate DD ON Reporting.dbo.fnGetDatePart(NCL.AddDate) = DD.FullDate
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC WITH (NOLOCK) ON NCL.NotebookID = NC.NotebookID
 JOIN SRV16.RabotaUA2.dbo.Notebook N WITH (NOLOCK) ON NC.NotebookID = N.ID
 JOIN SRV16.RabotaUA2.dbo.NotebookState NS_Cur WITH (NOLOCK) ON N.NotebookStateID = NS_Cur.ID
 JOIN SRV16.RabotaUA2.dbo.NotebookState NS_Log WITH (NOLOCK) ON NCL.ValInt = NS_Log.ID
 LEFT JOIN SRV16.RabotaUA2.dbo.NotebookCompanyMerged NCM WITH (NOLOCK) ON NCL.NotebookID = NCM.SourceNotebookID
 LEFT JOIN SRV16.RabotaUA2.dbo.Notebook NM WITH (NOLOCK) ON NCM.DestinationNotebookID = NM.ID
 LEFT JOIN SRV16.RabotaUA2.dbo.NotebookState NS_Mrg WITH (NOLOCK) ON NM.NotebookStateID = NS_Mrg.ID
WHERE NCL.PageID = 1
 AND NCL.EventID IN (2,3,4,11)
 AND DD.FullDate BETWEEN @StartDate AND @EndDate
 -- показывать цифры не ранее чем 22/05/2015 (дата включения логирования кнопки "Отправить на профиль")
 AND DD.FullDate >= '2015-05-22'
 )

SELECT Verificator, NotebookState, COUNT(DISTINCT NotebookID) AS NotebookCount
FROM C
GROUP BY Verificator, NotebookState

UNION

SELECT 
CASE a.LoginEmail
   	WHEN 'Annakr@rabota.ua' THEN 'Кравченко Анна'
	WHEN 'NataliyaM@rabota.ua' THEN 'Манжула Наталья'
	WHEN 'Evgeniyak@rabota.ua' THEN 'Коротич Евгения'
	WHEN 'juliap@rabota.ua' THEN 'Пичугина Юлия'
	WHEN 'YuraK@rabota.ua' THEN 'Ковалев Юрий'
	ELSE a.LoginEmail
 END AS Verificator, 
 'Количество заполненных анкет' NotebookState, COUNT(DISTINCT a.NotebookID) AS NotebookCount
FROM SRV16.RabotaUA2.dbo.Admin2_IdentifyNeeds a 
JOIN Reporting.dbo.DimDate DD ON Reporting.dbo.fnGetDatePart(a.AddDate) = DD.FullDate
WHERE 1=1 
--C.
and DD.FullDate BETWEEN @StartDate AND @EndDate
GROUP BY LoginEmail
;
--ORDER BY Verificator, NotebookState

