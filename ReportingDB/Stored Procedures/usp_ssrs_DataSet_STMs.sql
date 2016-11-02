-- ====================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-05-31
-- Description:	Процедура возвращает список "Sales Team менеджеров"
-- ======================================================================================================
CREATE PROCEDURE [dbo].[usp_ssrs_DataSet_STMs]
	
AS
 
BEGIN

SELECT Id AS ManagerID, Name AS ManagerName, TeamLead_ManagerID
FROM Analytics.dbo.Manager M
WHERE DepartmentId = 2
 AND EXISTS (SELECT * FROM Analytics.dbo.Manager WHERE STM_ManagerID = M.Id)
 AND TeamLead_ManagerID IS NOT NULL
ORDER BY M.TeamLead_ManagerID, M.Id;

END