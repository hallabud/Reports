-- ====================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-02-03
-- Description:	Процедура возвращает список Sales-команд.
--				Также выдает виртуальную Sales-команду "Все". 
--				Такой себе костыль вызванный ограничениями Reporting Services.
--				(для multi-valued параметров в ssrs нельзя установить NULL как значение по умолчанию).
--				(для даже не multi-valued параметров, у которых источник данных - хранимка, 
--				выставление "allow NULL values" не работает)
-- ======================================================================================================
CREATE PROCEDURE [dbo].[usp_ssrs_DataSet_SalesTeamsList]
	
AS

BEGIN

	SELECT 
	   N'Команда "' + Name + N'"' AS SalesTeamName
	 , Id AS SalesManagerID
	 , Name AS SalesManagerName 
	FROM Analytics.dbo.Manager M
	WHERE DepartmentID IN (2,3,4,10)
	 AND IsForTesting = 0
	 AND IsReportExcluding = 0
	 AND TeamLead_ManagerID IS NULL
	 AND EXISTS (SELECT * FROM Analytics.dbo.Manager WHERE TeamLead_ManagerID = M.Id)
	
	UNION ALL

	SELECT 'Все', 0, NULL
	ORDER BY SalesManagerName

END

