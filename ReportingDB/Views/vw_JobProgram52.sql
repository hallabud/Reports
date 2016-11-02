CREATE VIEW vw_JobProgram52

AS

SELECT Dir.Name AS StateName, M.Name AS Responsible, COUNT(*) AS ActionCount
FROM Analytics.dbo.CRM_Action A
 JOIN Analytics.dbo.CRM_Directory Dir ON A.StateID = Dir.ID AND Dir.Type = 'ActionState'
 JOIN Analytics.dbo.aspnet_Membership AM ON A.Responsible = AM.Email
 JOIN Analytics.dbo.Manager M ON AM.UserId = M.aspnet_UserUIN
WHERE JobProgramID = 52
GROUP BY Dir.Name, M.Name