
CREATE PROCEDURE dbo.usp_etl_ResumeCountByPZ

AS

BEGIN

DECLARE @FirstWeekDate DATE = (SELECT FirstWeekDate FROM Reporting.dbo.DimDate WHERE FullDate = CAST(GETDATE() AS DATE));

IF OBJECT_ID('tempdb..#T','U') IS NOT NULL DROP TABLE #T;
IF OBJECT_ID('tempdb..#C','U') IS NOT NULL DROP TABLE #C;

SET NOCOUNT ON;

SELECT WPZ.*, SG.SynonymousID
INTO #T
FROM Analytics.dbo.WorkPZ WPZ WITH (NOLOCK)
 JOIN Analytics.dbo.Synonymous S WITH (NOLOCK) ON WPZ.Name = S.Name
 JOIN Analytics.dbo.SynonymGroup SG WITH (NOLOCK) ON S.SynonymousID = SG.SynonymousID;

SELECT T.ID, T.Name AS Keyword, COUNT(RPZ.SynonymousID) AS Documents
INTO #C
FROM Analytics.dbo.ResumePZ AS RPZ WITH(NOLOCK)
 JOIN #T T ON T.SynonymousID = RPZ.SynonymousID
WHERE RPZ.Type IN (11, 12)
 AND EXISTS (SELECT * FROM Analytics.dbo.Resume R WHERE R.Id = RPZ.ResumeID AND R.State = 1 AND (AddDate >= DATEADD(YEAR, -1, GETDATE()) OR UpdateDate >= DATEADD(YEAR, -1, GETDATE())))
GROUP BY T.ID, T.Name

INSERT INTO [dbo].[ResumeCountByPZ] (FullDate, PZ, Work_ResumeCount, Rabota_ResumeCount)
SELECT @FirstWeekDate, WPZ.Name, WRC.Quantity, C.Documents  
FROM Analytics.dbo.Work_ResumeCountByPZ WRC WITH (NOLOCK)
 JOIN Analytics.dbo.WorkPZ WPZ WITH (NOLOCK) ON WRC.WorkPZID = WPZ.ID
 JOIN #C C ON WRC.WorkPZID = C.ID
WHERE CAST(WRC.Date AS DATE) = @FirstWeekDate
ORDER BY Name;

END;