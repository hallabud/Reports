-- ====================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-05-19
-- Description:	Процедура возвращает список Sales-команд.
-- ======================================================================================================
CREATE PROCEDURE [dbo].[usp_ssrs_DataSet_SalesTeamsList_Distinct]
	
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
	
END

