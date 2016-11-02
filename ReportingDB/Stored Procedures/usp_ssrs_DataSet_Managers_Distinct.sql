
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-05-19
-- Description:	Процедура возвращает список менеджеров, у которых есть Тимлид, а также самих тимлидов
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Modify date: 2016-05-19
-- Description:	Добавление сортировки по полю Name (имя-фамилия менеджера)
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Modify date: 2016-06-08
-- Description:	Не выводим менеджеров из "Лоялти группы" (поле IsLoyaltyGroup)
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Modify date: 2016-06-09
-- Description:	:) Выводим менеджеров из "Лоялти группы" (поле IsLoyaltyGroup)
--				Добавляем в вывод датасета поле IsLoyaltyGroup
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Modify date: 2016-07-06
-- Description:	Добавляем в вывод логин-емейл менеджера
-- ======================================================================================================
CREATE PROCEDURE [dbo].[usp_ssrs_DataSet_Managers_Distinct]
	
AS

BEGIN

	SELECT 
	   Id AS ManagerID
	 , Name AS ManagerName 
	 , COALESCE(TeamLead_ManagerID, Id) AS TeamLead_ManagerID
	 , IsLoyaltyGroup
	 , MMB.LoweredEmail AS Email
	FROM Analytics.dbo.Manager M
	 JOIN Analytics.dbo.aspnet_Membership MMB ON M.aspnet_UserUIN = MMB.UserId
	WHERE DepartmentID IN (2,3,4,10)
	 AND IsForTesting = 0
	 AND IsReportExcluding = 0
	 AND (TeamLead_ManagerID IS NOT NULL OR EXISTS (SELECT * FROM Analytics.dbo.Manager WHERE TeamLead_ManagerID = M.Id))
	ORDER BY ManagerName

END


