

-- ========================================================================================================
-- Author:		GranovskaA <AnastasiyaG@rabota.ua>
-- Create date: 2016-10-25
-- ========================================================================================================
-- Description:	Входящие параметры процедуры
--				@StartDate - начальная дата
--				@EndDate - конечная дата
--Данные для отчета	Transaction Report Temporary

--EXECUTE usp_ssrs_Report_TransactionData @StartDate ='2016-10-01', @EndDate='2016-10-25'	
-- ========================================================================================================

CREATE PROCEDURE [dbo].[usp_ssrs_Report_TransactionData]
 @StartDate DATETIME, @EndDate DATETIME

AS

-- -------------------------------------------------
-- для тестирования: вместо входящих параметров процедуры
--DECLARE @StartDate DATETIME
--DECLARE @EndDate DATETIME
--set @StartDate = '2016-10-01';
--set @EndDate   = '2016-10-25';


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


IF OBJECT_ID('tempdb..#Managers') IS NOT NULL DROP TABLE #Managers
SELECT 
	m.Id AS ManagerID
 	, m.Name AS ManagerName 
	, MMB.LoweredEmail AS Email
	, x.*
INTO #Managers
FROM SRV16.RabotaUA2.dbo.Manager M
	JOIN SRV16.RabotaUA2.dbo.aspnet_Membership MMB ON M.aspnet_UserUIN = MMB.UserId
	CROSS JOIN (SELECT DISTINCT CauseID FROM Analytics.dbo.Letter_Manager_15462_Log) x
WHERE 1=1
    --AND DepartmentID IN (12)
	AND m.Id in (318,320,328,337,340) 
ORDER BY m.Id, x.CauseID	


DECLARE @Res AS TABLE (ManagerID INT,RepType VARCHAR(250),CauseID INT,Number INT)
INSERT INTO @Res	

SELECT x.ManagerID, x.RepType, x.CauseID, x.Number --INTO #res
FROM (	
SELECT  m.ManagerID, 'Количество уведомлений' as RepType, m.CauseID, lg.Id as Number -- count(lg.Id) as Number
from 
#Managers m 
left join SRV16.RabotaUA2.dbo.Letter_Manager_15462_Log lg on lg.ManagerID=m.ManagerID AND lg.CauseID = m.CauseID
and  lg.[AddDate] between @StartDate and @EndDate + 1
--group by m.ManagerID, m.CauseID

union 

select m.ManagerID, 'Количество уникальных компаний, по которым приходили уведомления' as RepType, m.CauseID, lg.NotebookID as Number --count(distinct lg.NotebookID) as Number
from 
#Managers m 
left join SRV16.RabotaUA2.dbo.Letter_Manager_15462_Log lg on lg.ManagerID=m.ManagerID AND lg.CauseID = m.CauseID
and lg.[AddDate] between @StartDate and @EndDate + 1
--group by m.ManagerID, m.CauseID

union 

SELECT mg.ManagerId,'Количество компаний, по которым были выполнены действия' as RepType, mg.CauseID, x.NotebookID AS Number -- COUNT(DISTINCT x.NotebookID)
FROM 
#Managers mg
left JOIN 
(
 SELECT m.id AS ManagerId,lg.CauseID,a.NotebookID
 from SRV16.RabotaUA2.dbo.CRM_Action A
 JOIN SRV16.RabotaUA2.dbo.aspnet_Membership AM ON A.Responsible = AM.Email
 JOIN SRV16.RabotaUA2.dbo.Manager M ON AM.UserID = M.aspnet_UserUIN	
 JOIN SRV16.RabotaUA2.dbo.Letter_Manager_15462_Log LG ON LG.NotebookID=a.NotebookID
 WHERE 1=1
 AND A.StateID = 2
 AND TypeID NOT IN (6,8,9)
 AND IsForTesting = 0 AND IsReportExcluding = 0
 AND CompleteDate BETWEEN @StartDate AND @EndDate + 1
 AND lg.[AddDate] between @StartDate and @EndDate + 1
 
) x ON mg.ManagerId = x.ManagerId AND mg.CauseID = x.CauseID
--GROUP BY mg.ManagerId, mg.CauseID

union 

SELECT mg.ManagerId,'Количество выполненных действий' as RepType, mg.CauseID, x.ID as number --COUNT(DISTINCT x.ID)
FROM 
#Managers mg
left JOIN 
(
 SELECT m.id AS ManagerId,lg.CauseID,a.ID
 from SRV16.RabotaUA2.dbo.CRM_Action A
 JOIN SRV16.RabotaUA2.dbo.aspnet_Membership AM ON A.Responsible = AM.Email
 JOIN SRV16.RabotaUA2.dbo.Manager M ON AM.UserID = M.aspnet_UserUIN	
 JOIN SRV16.RabotaUA2.dbo.Letter_Manager_15462_Log LG ON LG.NotebookID=a.NotebookID
 WHERE 1=1
 AND A.StateID = 2
 AND TypeID NOT IN (6,8,9)
 AND IsForTesting = 0 AND IsReportExcluding = 0
 AND CompleteDate BETWEEN @StartDate AND @EndDate + 1
 AND lg.[AddDate] between @StartDate and @EndDate + 1
 
) x ON mg.ManagerId = x.ManagerId AND mg.CauseID = x.CauseID
--GROUP BY mg.ManagerId, mg.CauseID

union 

SELECT mg.ManagerId,'Количество сделок' as RepType, mg.CauseID, x.id as Number --COUNT(DISTINCT x.id)
FROM 
#Managers mg
left JOIN 
(
 SELECT m.id AS ManagerId,lg.CauseID,a.id
 from SRV16.RabotaUA2.dbo.CRM_Deal A
 JOIN SRV16.RabotaUA2.dbo.aspnet_Membership AM ON A.loginEMail_DealOwner = AM.Email
 JOIN SRV16.RabotaUA2.dbo.Manager M ON AM.UserID = M.aspnet_UserUIN	
 JOIN SRV16.RabotaUA2.dbo.Letter_Manager_15462_Log LG ON LG.NotebookID=a.NotebookID
 WHERE 1=1
 AND A.StateID = 2
 AND a.CloseDate BETWEEN @StartDate AND @EndDate + 1 -- берем кол-во закрытых, т.е. оплаченных сделок(согласно BI-139)
 AND lg.[AddDate] between @StartDate and @EndDate + 1
 
) x ON mg.ManagerId = x.ManagerId AND mg.CauseID = x.CauseID
--GROUP BY mg.ManagerId, mg.CauseID
) x

IF OBJECT_ID('tempdb..#res') IS NOT NULL DROP TABLE #res
SELECT * into #res FROM @res
-------------------------------------------------------------
CREATE INDEX ii ON #res(ManagerId);
CREATE INDEX i2 ON #res(CauseID);



IF OBJECT_ID('tempdb..#R') IS NOT NULL DROP TABLE #R
;WITH cte AS (
	
SELECT r.ManagerId, m.name , r.RepType, r.CauseID, count(distinct r.Number) AS Number
FROM #res r
JOIN SRV16.RabotaUA2.dbo.Manager m ON m.Id = r.ManagerID
GROUP BY r.ManagerId, m.name , r.RepType, r.CauseID

UNION 

SELECT r.ManagerId, m.name , r.RepType, 100 as CauseID, count(distinct r.Number) AS Number
FROM #res r
JOIN SRV16.RabotaUA2.dbo.Manager m ON m.Id = r.ManagerID
GROUP BY r.ManagerId, m.name , r.RepType
)

select Res.* INTO #R 
FROM
(
SELECT r.ManagerId, m.name , r.RepType, r.CauseID, r.Number
FROM cte r
JOIN SRV16.RabotaUA2.dbo.Manager m ON m.Id = r.ManagerID

UNION 

select 99999 AS ManagerId, 'По всей группе' AS name, r.RepType,r.CauseID, sum(r.Number) AS Number 
FROM cte r
GROUP BY r.RepType,r.CauseID
) res
--select * from cte



--select * from #R
------------------Final-------------------- 
SELECT Res.*, 
CauseItemName =
CASE WHEN Res.CauseID = 1 then 'изменение рекомендованного канала продаж с eCommerce на SalesForce'
     WHEN Res.CauseID = 2 then 'исчерпан бесплатный дневной лимит на просмотр контактов в Базе Резюме'
     WHEN Res.CauseID = 3 then 'использованы все бесплатные публикации, начисляемые ежемесячно'
	 WHEN Res.CauseID = 4 then 'компания посетила раздел «Услуги»'
	 WHEN Res.CauseID = 5 then 'компания приобрела "Бизнес-размещение" на work.ua'
	 WHEN Res.CauseID = 100 then 'Общий итог'
END
FROM
(
SELECT r.*, 'a' AS SortNum FROM #R r
UNION 
SELECT r.ManagerId, r.name , '% Конверсии по типу уведомлений' as RepType, r.CauseID,  
Number = CASE WHEN r.Number = 0 THEN 0 ELSE ROUND(((cast(r.Number AS float))/cast(r1.Number AS FLOAT)*100),0) END,
'b' AS SortNum
FROM 
#R r 
JOIN #R r1 ON  r.CauseID = r1.CauseID AND r.ManagerId=r1.ManagerId
WHERE r.RepType = 'Количество сделок' 
              AND r1.RepType = 'Количество выполненных действий'
) Res

