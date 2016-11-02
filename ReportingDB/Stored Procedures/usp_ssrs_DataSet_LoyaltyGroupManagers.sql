
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-02-05
-- Description:	Процедура возвращает список менеджеров, входящих "Группу подержки лояльности", а также
--				так называемый "буфер", на который переводят блокноты, которые не за кем закрепить.				
--				Тупо руками прописываем айди менеджеров из таблицы Manager, т.к. никакими другими 
--				признаками их выделить невозможно, а задача есть.
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-04-13
-- Description: Отбираем менеджеров Лоялти Группы по признаку IsLoyaltyGroup, который был добавлен
--				в таблицу Manager. Так называемый "буфер" отбираем по признаку IsTatarovaGroup.
--				Выводим только менеджеров DepartmentID = 2 (Sales Force)
-- ======================================================================================================
CREATE PROCEDURE [dbo].[usp_ssrs_DataSet_LoyaltyGroupManagers]
	
AS

BEGIN

	SELECT 
	   Id AS ManagerID
	 , Name AS ManagerName 
	FROM Analytics.dbo.Manager M
	WHERE M.DepartmentID = 2
	 AND (M.IsLoyaltyGroup = 1 OR M.IsTatarovaGroup = 1)
	ORDER BY ManagerName

END