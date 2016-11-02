
-- ======================================================================================================
-- Author:			michael <michael@rabota.ua>
-- Modified date:	2016-03-16
-- Description:		Показывать вакансии только тех компаний, у которых в блокноте на rabota.ua есть 
--					как минимум одна опубликованная вакансия
-- ======================================================================================================
-- ======================================================================================================
-- Author:			michael <michael@rabota.ua>
-- Modified date:	2016-02-12
-- Description:		Добавляем в возвращаемый список также те вакансии, дата которых (VacancyDate)
--					приходится на вчерашний день
-- ======================================================================================================
-- ======================================================================================================
-- Author:			michael <michael@rabota.ua>
-- Create date:		2016-02-12
-- Description:		Процедура возвращает список вакансий на work.ua, которые были добавлены вчера 
--					и не привязаны к какой-либо вакансии на rabota.ua, от компаний, привязанных 
--					к МЕГА-проверенным блокнотам на rabota.ua
-- ======================================================================================================

CREATE PROCEDURE [dbo].[usp_ssrs_Report_YesterdayWorkVacanciesUnlinked]
 
 AS

SELECT SC.Name AS CompanyName, SV.Name AS VacancyName
 , 'http://admin8.rabota.ua/pages/transfer/link.aspx?vacancyId=' 
	+ CONVERT(NVARCHAR, SV.SpiderVacancyID)
	+ '&source=' + CONVERT(NVARCHAR, SV.Source)
	+ '&notebookId=' + CONVERT(NVARCHAR, SC.NotebookId)
	+ '&city=' + SV.City
	+ '&vname=' + SV.Name AS URL
FROM SRV16.RabotaUA2.dbo.SpiderVacancy SV WITH (NOLOCK)
 JOIN SRV16.RabotaUA2.dbo.SpiderCompany SC WITH (NOLOCK) ON SC.Source = 1 AND SV.SpiderCompanyID = SC.CompanyId
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC WITH (NOLOCK) ON SC.NotebookId = NC.NotebookId
WHERE SV.Source = 1
 AND IsPublish = 1
 AND SV.VacancyID IS NULL
 AND (SV.AddDate BETWEEN DATEADD(DAY, -1, dbo.fnGetDatePart(GETDATE())) AND dbo.fnGetDatePart(GETDATE()) OR SV.VacancyDate = DATEADD(DAY, -1, dbo.fnGetDatePart(GETDATE())))
 AND EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.VacancyPublished VP WITH (NOLOCK) WHERE VP.NotebookID = NC.NotebookId)
ORDER BY NC.NotebookId;