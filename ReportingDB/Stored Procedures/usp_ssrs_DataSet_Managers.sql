
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-02-03
-- Description:	Процедура возвращает список менеджеров
--				Также выдает виртуального менеджера "Все". 
--				Такой себе костыль вызванный ограничениями Reporting Services.
--				(для multi-valued параметров в ssrs нельзя установить NULL как значение по умолчанию).
--				(для даже не multi-valued параметров, у которых источник данных - хранимка, 
--				выставление "allow NULL values" не работает)
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
CREATE PROCEDURE [dbo].[usp_ssrs_DataSet_Managers]
	
AS

BEGIN

	SELECT 
	   Id AS ManagerID
	 , Name AS ManagerName 
	 , COALESCE(TeamLead_ManagerID, Id) AS TeamLead_ManagerID
	 , IsLoyaltyGroup
	FROM Analytics.dbo.Manager M
	WHERE DepartmentID IN (2,3,4,10)
	 AND IsForTesting = 0
	 AND IsReportExcluding = 0
	 AND (TeamLead_ManagerID IS NOT NULL OR EXISTS (SELECT * FROM Analytics.dbo.Manager WHERE TeamLead_ManagerID = M.Id))

	UNION ALL

	SELECT 0, 'Все', 0, 0
	ORDER BY Name

END


