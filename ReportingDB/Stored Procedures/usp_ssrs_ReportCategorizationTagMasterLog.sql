
CREATE PROCEDURE [dbo].[usp_ssrs_ReportCategorizationTagMasterLog]
 @StartDate DATETIME, @EndDate DATETIME

AS

DECLARE @EndDatePlus1 DATETIME; SET @EndDatePlus1 = DATEADD(DAY, 1, @EndDate);

SELECT 
   CASE SLog.ActionID
    WHEN 1 THEN D.Name + ' "' + SLog.ObjectName + '" ' + 'к группе синонимов "' + SG.Name + '"'
    WHEN 2 THEN D.Name + ' "' + SLog.ObjectName + '" ' + 'из группы синонимов "' + SG.Name + '"'
    WHEN 3 THEN D.Name + ' "' + SLog.ObjectName + '" ' + 'в группу синонимов "' + SG.Name + '"'
    WHEN 4 THEN D.Name + ' "' + SLog.ObjectName + '" ' + 'из группы синонимов "' + SG.Name + '"'
    WHEN 5 THEN D.Name + ' "' + SG.Name + '" '
    WHEN 6 THEN D.Name + ' "' + CASE SLog.ObjectID WHEN 1 THEN 'в обработке"' WHEN 2 THEN 'надо вернуться"' WHEN 3 THEN 'готово"' END
    WHEN 7 THEN D.Name + ' "' + SLog.ObjectName + '" ' + 'к группе синонимов "' + SG.Name + '"'
    WHEN 8 THEN D.Name + ' "' + SLog.ObjectName + '" ' + 'из группы синонимов "' + SG.Name + '"'
    WHEN 9 THEN D.Name + ' "' + SLog.ObjectName + '" '
    WHEN 10 THEN D.Name + ' "' + SLog.ObjectName + '" '
    WHEN 11 THEN D.Name + ' "' + SLog.ObjectName + '" '
    WHEN 12 THEN REPLACE(D.Name, '##TagName##', '"'+SLog.ObjectName+'"') + ' "' + SG.Name + '"'
    WHEN 13 THEN REPLACE(D.Name, '##TagName##', '"'+SLog.ObjectName+'"') + ' "' + SG.Name + '"'
    ELSE D.Name
   END AS 'Description'
 , SLog.ActionID 
 , SLog.AddDate AS 'LogAddDate'
 , CONVERT(VARCHAR, SLog.AddDate, 104) + ' ' + CONVERT(VARCHAR, SLog.AddDate, 108) AS 'LogAddDate104'
 , SLog.LoginEMail
 , D.Name AS 'ActionName'
 , SLog.ObjectID
 , SLog.ObjectName
 , SLog.SynonymousID
 , SG.Name AS 'SynGroupName'
 , SLog.ObjectID2
 , SLog.ObjectName2
FROM Analytics.dbo.SynonymGroup_LogByUser SLog 
 JOIN Analytics.dbo.Directory D ON SLog.ActionID = D.ID AND D.Type = 'UserActionLog' AND D.GroupName = 'Synonymous'
 JOIN Analytics.dbo.SynonymGroup SG ON SLog.SynonymousID = SG.SynonymousID
WHERE SLog.AddDate BETWEEN @StartDate AND @EndDatePlus1;