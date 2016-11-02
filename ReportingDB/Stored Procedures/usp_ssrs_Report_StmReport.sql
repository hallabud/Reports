
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-05-31
-- Description:	Процедура возвращает по менеджерам подчиняющимся выбранноому STM-менеджеру 
--				квартальные плановые и фактические значения следующих показателей
--				- продажи
--				- кол-во платных клиентов
--				- удельный вес уникальных вакансий
--				- охват (пока показываем только план, так как неизвестно как считать факт)
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Update date: 2016-05-31
-- Description:	Добавлен расчет и вывод кол-ва выполненных действий 
--				с типом действия <> 'системное действие' (TypeID = 9)
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Update date: 2016-05-31
-- Description:	Берем данные с продакшн-базы через линкед-сервер
--				(в разы тормозит скорость отработки процедуры, но увы так заказали. 
--				Наблюдаются задержки типа OLEDB)
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Update date: 2016-06-01
-- Description:	Кол-во выполненных действий считаем "за вчера"
--				Охват считаем как "Кол-во "проконтактированных" активных (в момент контакта) компаний
--				за период от "Конечная дата - 30 дней" до "Конечная дата" / Кол-во компаний, которые 
--				были активными за период от "Конечная дата - 30 дней" до "Конечная дата". Активность - 
--				была как минимум одна вакансия или на rabota.ua или на work.ua
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Update date: 2016-06-02
-- Description:	Кол-во выполненных действий считаем "за сегодня"
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Update date: 2016-06-29
-- Description:	Кол-во выполненных действий считаем "за вчера"
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Update date: 2016-07-04
-- Description:	В расчете финансовой реализации считаем не по дате добавления записи о платеже в БД
--				(OAP.AddDate), а по указанной дате платежа (PayDate)
-- ======================================================================================================


CREATE PROCEDURE [dbo].[usp_ssrs_Report_StmReport]
	(@YearNum SMALLINT, @QuarterNum TINYINT, @StmID SMALLINT)

AS

BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	IF OBJECT_ID('tempdb..#Managers','U') IS NOT NULL DROP TABLE #Managers;
	IF OBJECT_ID('tempdb..#Payments','U') IS NOT NULL DROP TABLE #Payments;
	IF OBJECT_ID('tempdb..#Clients','U') IS NOT NULL DROP TABLE #Clients;
	IF OBJECT_ID('tempdb..#UnqVacancy','U') IS NOT NULL DROP TABLE #UnqVacancy;
	IF OBJECT_ID('tempdb..#Actions','U') IS NOT NULL DROP TABLE #Actions;
	IF OBJECT_ID('tempdb..#ActiveCompanies','U') IS NOT NULL DROP TABLE #ActiveCompanies;
	IF OBJECT_ID('tempdb..#ActiveCompaniesCount','U') IS NOT NULL DROP TABLE #ActiveCompaniesCount;
	IF OBJECT_ID('tempdb..#ActiveCompaniesWithAction','U') IS NOT NULL DROP TABLE #ActiveCompaniesWithAction;

	DECLARE @ReportDateKey INT = (SELECT MAX(Date_key) FROM Reporting.dbo.DimDate WHERE FullDate <= GETDATE() AND QuarterNum = @QuarterNum AND YearNum = @YearNum);
	DECLARE @ReportDate DATETIME = (SELECT FullDate FROM Reporting.dbo.DimDate WHERE Date_key = @ReportDateKey);
	DECLARE @ReportDateMinus1 DATETIME = DATEADD(DAY, -1, @ReportDate);
	DECLARE @ReportDateMinusMonth DATETIME = DATEADD(MONTH, -1, @ReportDate);
	DECLARE @ReportDateKeyMinusMonth INT = (SELECT Date_key FROM Reporting.dbo.DimDate WHERE FullDate = @ReportDateMinusMonth);
	DECLARE @MayDay DATE = '2016-04-01'; -- дата с которой появился период "3 месяца для установления лояльности"
	DECLARE @ThreeMonthAgo DATE = DATEADD(MONTH, -3, @ReportDateKey);

	SELECT M.Id, M.Name, MMB.Email
	INTO #Managers
	FROM Analytics.dbo.Manager M
	 JOIN Analytics.dbo.aspnet_Membership MMB ON M.aspnet_UserUIN = MMB.UserId
	WHERE STM_ManagerId = @StmID OR M.Id = @StmID;

	-- Финансовая реализация - кол-во платежей по счетам
	SELECT OA.LoginEMail_PaidOwner, SUM(OAP.PaySum) AS SalesFact
	INTO #Payments
	FROM SRV16.RabotaUA2.dbo.Order_AccPayment OAP
	 JOIN SRV16.RabotaUA2.dbo.Order_Acc OA ON OAP.AccYear = OA.Year AND OAP.AccID = OA.ID
	WHERE DATEPART(YEAR, OAP.PayDate) = @YearNum AND DATEPART(QUARTER, OAP.PayDate) = @QuarterNum
	 AND EXISTS (SELECT * FROM #Managers WHERE OA.LoginEMail_PaidOwner = Email)
	GROUP BY OA.LoginEMail_PaidOwner;

	-- Количество платных клиентов
	SELECT C.ManagerEmail, COUNT(*) AS ClientsFact
	INTO #Clients
	FROM Reporting.dbo.DimCompany C
	 JOIN Reporting.dbo.FactCompanyStatuses CS ON C.Company_key = CS.Company_key AND CS.Date_key = @ReportDateKey
	WHERE EXISTS (SELECT * FROM #Managers WHERE C.ManagerEmail = Email)
	 AND CS.HasPaidServices = 1
	GROUP BY C.ManagerEmail;

	-- Уникальные вакансии
	SELECT C.ManagerEmail, 1. * SUM(CS.VacancyNum) / SUM(CS.VacancyNum + CS.UnqWorkVacancyNum) AS UniqueVacancyFact
	INTO #UnqVacancy
	FROM Reporting.dbo.DimCompany C
	 JOIN Reporting.dbo.FactCompanyStatuses CS ON C.Company_key = CS.Company_key AND CS.Date_key = @ReportDateKey
	WHERE EXISTS (SELECT * FROM #Managers WHERE C.ManagerEmail = Email)
	 AND C.WorkConnectionGroup = 'Привязанные компании'
	 AND (ManagerStartDate < @MayDay OR ManagerStartDate < @ThreeMonthAgo) -- Компания взята в работу менеджером или до 1/04/2016, или не позже чем 3 мес. назад
	GROUP BY C.ManagerEmail;

	-- Список активных компаний в течении последнего месяца
	SELECT DISTINCT C.ManagerEmail, C.NotebookId
	INTO #ActiveCompanies
	FROM Reporting.dbo.DimCompany C
	 JOIN Reporting.dbo.FactCompanyStatuses CS ON C.Company_key = CS.Company_key
	WHERE EXISTS (SELECT * FROM #Managers WHERE C.ManagerEmail = Email)
	 AND CS.Date_key BETWEEN @ReportDateKeyMinusMonth AND @ReportDateKey
	 AND CS.VacancyNum | ISNULL(CS.WorkVacancyNum,0) > 0
	
	-- Кол-во активных компаний в течении последнего месяца
	SELECT ManagerEmail, COUNT(*) AS ActiveCompaniesCount
	INTO #ActiveCompaniesCount
	FROM #ActiveCompanies 
	GROUP BY ManagerEmail

	-- Проконтактированные активные компании в течении последнего месяца
	SELECT Responsible, COUNT(DISTINCT NotebookID) AS CompaniesWithActionMonth
	INTO #ActiveCompaniesWithAction
	FROM SRV16.RabotaUA2.dbo.CRM_Action A
	 JOIN #Managers M ON A.Responsible = M.Email
	WHERE A.CompleteDate BETWEEN @ReportDateMinusMonth AND @ReportDate + 1
	 --AND EXISTS (SELECT * FROM #Managers WHERE A.Responsible = Email)
	 AND EXISTS (SELECT * FROM #ActiveCompanies WHERE NotebookId = A.NotebookID AND ManagerEmail = M.Email)
	 AND A.StateID = 2 AND A.TypeID NOT IN (8,9)
	GROUP BY Responsible;

	-- Выполоненные действия
	SELECT Responsible, COUNT(*) AS ActionsFact
	INTO #Actions
	FROM SRV16.RabotaUA2.dbo.CRM_Action A
	WHERE A.CompleteDate BETWEEN @ReportDateMinus1 AND @ReportDate
	 AND EXISTS (SELECT * FROM #Managers WHERE A.Responsible = Email)
	 AND A.StateID = 2 AND A.TypeID <> 9
	GROUP BY Responsible;

	SELECT 
	   M.Id, M.Name, M.Email
	 , TQO.SalesPlan, P.SalesFact
	 , TQO.ClientsPlan, CL.ClientsFact
	 , TQO.UniqueVacancyPlan, UV.UniqueVacancyFact
	 , TQO.CoveragePlan
	 , 1. * ACA.CompaniesWithActionMonth / ACC.ActiveCompaniesCount AS CoverageFact
	 , ISNULL(A.ActionsFact, 0) AS ActionsFact
	 , ACA.CompaniesWithActionMonth
	 , ACC.ActiveCompaniesCount
	FROM #Managers M
	 JOIN Reporting.dbo.TargetsQuarterOverall TQO ON M.Id = TQO.ManagerID AND TQO.YearNum = @YearNum AND TQO.QuarterNum = @QuarterNum
	 LEFT JOIN #Payments P ON M.Email = P.LoginEMail_PaidOwner
	 LEFT JOIN #Clients CL ON M.Email = CL.ManagerEmail
	 LEFT JOIN #UnqVacancy UV ON M.Email = UV.ManagerEmail
	 LEFT JOIN #Actions A ON M.Email = A.Responsible
	 LEFT JOIN #ActiveCompaniesCount ACC ON M.Email = ACC.ManagerEmail
	 LEFT JOIN #ActiveCompaniesWithAction ACA ON M.Email = ACA.Responsible;

	DROP TABLE #Managers;
	DROP TABLE #Payments;
	DROP TABLE #Clients;
	DROP TABLE #UnqVacancy;
	DROP TABLE #Actions;
	DROP TABLE #ActiveCompanies;
	DROP TABLE #ActiveCompaniesCount;
	DROP TABLE #ActiveCompaniesWithAction;

 END

