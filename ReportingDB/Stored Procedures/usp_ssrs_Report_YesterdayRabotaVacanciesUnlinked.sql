
-- ======================================================================================================
-- Author:			michael <michael@rabota.ua>
-- Create date:		2016-10-07
-- Description:		Процедура возвращает список ваканксий, опубликованных вчера на rabota.ua, которые
--					не привязаны к вакансии на work.ua
-- JIRA #:			https://rabota.atlassian.net/browse/BI-59
-- ======================================================================================================

CREATE PROCEDURE [dbo].[usp_ssrs_Report_YesterdayRabotaVacanciesUnlinked]

AS

BEGIN

	DECLARE @YesterdayStartDT datetime = dbo.fnGetDatePart(DATEADD(DAY, -1, GETDATE()));
	DECLARE @TodayStartDT datetime = dbo.fnGetDatePart(GETDATE());

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- временная таблица для сохранения NotebookID (айди блокнотов/компаний), у которых есть как минимум одна опубликованная вакансия на work.ua
	-- можно было бы смотреть на VacancyCount в таблице SpiderCompany, но это цифра забирается другим спайдером, поэтому ориентируемся на SpiderVacancy
	IF OBJECT_ID('tempdb..#NotebooksWithPubsOnWork','U') IS NOT NULL DROP TABLE #NotebooksWithPubsOnWork;

	SELECT DISTINCT SC.NotebookId
	INTO #NotebooksWithPubsOnWork
	FROM SRV16.RabotaUA2.dbo.SpiderVacancy SV
	 JOIN SRV16.RabotaUA2.dbo.SpiderCompany SC ON SV.SpiderCompanyID = SC.CompanyID AND SC.Source = 1
	WHERE IsPublish = 1;

	SELECT 
	   NC.NotebookId 
	 , NC.Name AS CompanyName
	 , VP.ID AS VacancyID
	 , VP.Name AS VacancyName
	 , 'http://admin8.rabota.ua/pages/transfer/link.aspx?vacancyId=' + CONVERT(varchar, VP.ID) + '&Source=0&notebookId=' + CONVERT(varchar, VP.NotebookID) + '&city=' + C.Name + '&vname=' + VP.Name AS VacancyLinkURL
	FROM SRV16.RabotaUA2.dbo.VacancyPublished VP
	 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC ON VP.NotebookID = NC.NotebookId
	 JOIN SRV16.RabotaUA2.dbo.VacancyCity VC ON VP.ID = VC.VacancyId
	 JOIN SRV16.RabotaUA2.dbo.City C ON VC.CityId = C.Id
	WHERE VP.StateDate BETWEEN @YesterdayStartDT AND @TodayStartDT -- вакансия на rabota.ua была опубликована или переопубликована вчера
	 AND EXISTS (SELECT * FROM #NotebooksWithPubsOnWork WHERE NotebookId = VP.NotebookID) -- у компании есть опубликованная вакансия на work.ua
	 AND NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.SpiderVacancy SV WHERE SV.VacancyID = VP.ID AND SV.IsPublish = 1) -- вакансия на rabota.ua не привязана к вакансии на work. ua
	 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.Notebook N WHERE N.Id = VP.NotebookID AND N.NotebookStateId IN (5,7)) -- компания в статусе "проверенный" или "мегапроверенный"
	ORDER BY NotebookID, VacancyID;

END;
