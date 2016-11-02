
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-05-31
-- Description:	Процедура возвращает список компаний, которые находятся на льготном периоде.
--				Льготный период на установление лояльности - это 3 месяца с даты начала работы
--				менеджера с компанией ManagerStartDate, без учета компаний взятых в работу до 01/04/2016
-- ======================================================================================================
CREATE PROCEDURE dbo.usp_ssrs_Report_ExemptionPeriod
	(@ManagerIDs NVARCHAR(1000))

AS

DECLARE @MayDay DATE = '2016-04-01'; -- дата с которой появился период "3 месяца для установления лояльности"
DECLARE @ThreeMonthAgo DATE = DATEADD(MONTH, -3, CONVERT(DATE, GETDATE()));

SELECT NotebookId
 , CompanyName
 , ManagerStartDate
 , DATEDIFF(DAY, GETDATE(), DATEADD(MONTH, 3, ManagerStartDate)) DaysLeft
 , ManagerName
 , VacancyNum
 , UnqWorkVacancyNum
 , 1. * VacancyNum / NULLIF((VacancyNum + UnqWorkVacancyNum),0) AS UnqVacancyWeight
FROM dbo.DimCompany C
 JOIN Analytics.dbo.aspnet_Membership MMB ON C.ManagerEmail = MMB.Email
 JOIN Analytics.dbo.Manager M ON MMB.UserId = M.aspnet_UserUIN
WHERE ManagerStartDate >= @MayDay AND ManagerStartDate >= @ThreeMonthAgo
 AND WorkConnectionGroup = 'Привязанные компании'
 AND M.ID IN (SELECT Value FROM dbo.udf_SplitString(@ManagerIDs, ','))
ORDER BY ManagerStartDate;
