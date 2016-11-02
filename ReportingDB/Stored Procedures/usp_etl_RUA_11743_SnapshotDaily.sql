CREATE PROCEDURE dbo.usp_etl_RUA_11743_SnapshotDaily
AS

DECLARE @Today DATETIME; SET @Today = dbo.fnGetDatePart(GETDATE());
DECLARE @Yesterday DATETIME; SET @Yesterday = @Today - 1;

--3		нет требований
--33	нет обязанностей
--34	нет условий
--39	некорректная должность
--48	некорректное описание

INSERT INTO Reporting.dbo.RUA_11743_SnapshotDaily
SELECT @Yesterday AS ReportDate, 
(
SELECT COUNT(*) 
FROM Analytics.dbo.BlockingHistory 
WHERE VacancyID IS NOT NULL
 AND AddDate BETWEEN @Yesterday AND @Today
 AND (',' + BlockingReasonIDs + ',' LIKE '%,3,%'
      OR ',' + BlockingReasonIDs + ',' LIKE '%,33,%'
	  OR ',' + BlockingReasonIDs + ',' LIKE '%,34,%'
	  OR ',' + BlockingReasonIDs + ',' LIKE '%,39,%'
	  OR ',' + BlockingReasonIDs + ',' LIKE '%,48,%')
) AS VacancyBlocked
,(
SELECT COUNT(*)
FROM Analytics.dbo.VacancyPublished VP
 JOIN Analytics.dbo.VacancyExtra VE ON VP.ID = VE.VacancyID
WHERE VE.IsModerated = 1
 AND EXISTS (SELECT * 
			 FROM Analytics.dbo.BlockingHistory 
			 WHERE VacancyID = VE.VacancyID 
				AND AddDate BETWEEN @Yesterday AND @Today
				AND (',' + BlockingReasonIDs + ',' LIKE '%,3,%'
					  OR ',' + BlockingReasonIDs + ',' LIKE '%,33,%'
					  OR ',' + BlockingReasonIDs + ',' LIKE '%,34,%'
					  OR ',' + BlockingReasonIDs + ',' LIKE '%,39,%'
					  OR ',' + BlockingReasonIDs + ',' LIKE '%,48,%'))
) AS VacancyPublished;
