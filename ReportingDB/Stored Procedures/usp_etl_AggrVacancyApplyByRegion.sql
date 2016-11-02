
CREATE PROCEDURE dbo.usp_etl_AggrVacancyApplyByRegion

AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @PreviousWeekStartDate DATETIME = (SELECT FirstWeekDate FROM Reporting.dbo.DimDate WHERE FullDate = DATEADD(WEEK, -1, CONVERT(DATE, GETDATE())));
DECLARE @PreviousWeekLastDate DATETIME = (SELECT LastWeekDate FROM Reporting.dbo.DimDate WHERE FullDate = DATEADD(WEEK, -1, CONVERT(DATE, GETDATE())));
DECLARE @YearNum INT = (SELECT YearNum FROM Reporting.dbo.DimDate WHERE FullDate = @PreviousWeekStartDate);
DECLARE @WeekNum INT = (SELECT WeekNum FROM Reporting.dbo.DimDate WHERE FullDate = @PreviousWeekStartDate);
DECLARE @WeekName NCHAR(13) = (SELECT WeekName FROM Reporting.dbo.DimDate WHERE FullDate = @PreviousWeekStartDate);

WITH C AS 
 (
SELECT COALESCE(OBL.Id, C.Id) AS CityId, COALESCE(OBL.Name, C.Name) AS Region, V.Id AS VacancyID, VATV.ID AS ApplyID
FROM SRV16.RabotaUA2.dbo.VacancyApplyToVacancy VATV
 JOIN SRV16.RabotaUA2.dbo.Vacancy V ON VATV.VacancyId = V.Id
 JOIN SRV16.RabotaUA2.dbo.VacancyCity VC ON V.Id = VC.VacancyId
 JOIN SRV16.RabotaUA2.dbo.City C ON VC.CityId = C.Id
 LEFT JOIN SRV16.RabotaUA2.dbo.City OBL ON C.OblastCityId = OBL.Id
WHERE VATV.AddDate BETWEEN @PreviousWeekStartDate AND @PreviousWeekLastDate + 1

UNION ALL

SELECT COALESCE(OBL.Id, C.Id) AS CityId, COALESCE(OBL.Name, C.Name) AS Region, V.Id AS VacancyID, RTV.ID AS ApplyID
FROM SRV16.RabotaUA2.dbo.ResumeToVacancy RTV
 JOIN SRV16.RabotaUA2.dbo.Vacancy V ON RTV.VacancyId = V.Id
 JOIN SRV16.RabotaUA2.dbo.VacancyCity VC ON V.Id = VC.VacancyId
 JOIN SRV16.RabotaUA2.dbo.City C ON VC.CityId = C.Id
 LEFT JOIN SRV16.RabotaUA2.dbo.City OBL ON C.OblastCityId = OBL.Id
WHERE RTV.AddDate BETWEEN @PreviousWeekStartDate AND @PreviousWeekLastDate + 1
 )
 , VacancyApplyByRegion AS
 (
SELECT 
   @YearNum AS YearNum
 , @WeekNum AS WeekNum
 , @WeekName AS WeekName
 , CityId
 , Region
 , COUNT(*) AS ApplyCount
FROM C
GROUP BY CityId, Region
 )
 , VacancyCountByCity AS
 (
SELECT DD.FullDate, COALESCE(OBL.Id, S2.CityId) AS CityId, SUM(VacancyCount) VacancyCount
FROM SRV16.RabotaUA2.dbo.Spider2VacancyCountByCity S2
 JOIN Reporting.dbo.DimDate DD ON CONVERT(DATE, S2.[Date]) = DD.FullDate
 JOIN SRV16.RabotaUA2.dbo.City C ON S2.CityId = C.Id
 LEFT JOIN SRV16.RabotaUA2.dbo.City OBL ON C.OblastCityId = OBL.Id
WHERE DD.YearNum = @YearNum 
 AND DD.WeekNum = @WeekNum
 AND S2.Source = 0
 AND S2.CityID <> 0
GROUP BY DD.FullDate, COALESCE(OBL.Id, S2.CityId)
 )
 , VacancyCountByRegion AS
 (
SELECT CityId, AVG(VacancyCount) AS AvgVacancyCount
FROM VacancyCountByCity
GROUP BY CityId
 )
INSERT INTO Reporting.dbo.AggrVacancyApplyByRegion
SELECT YearNum, WeekNum, WeekName, Region, AvgVacancyCount, ApplyCount, 1. * ApplyCount / AvgVacancyCount AS ApplyPerVacancy 
FROM VacancyApplyByRegion VABR
 JOIN VacancyCountByRegion VCBR ON VABR.CityId = VCBR.CityId;