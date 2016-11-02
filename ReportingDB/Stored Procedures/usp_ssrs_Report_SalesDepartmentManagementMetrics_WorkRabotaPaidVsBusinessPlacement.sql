
CREATE PROCEDURE dbo.usp_ssrs_Report_SalesDepartmentManagementMetrics_WorkRabotaPaidVsBusinessPlacement

AS

-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-08-09
-- Description:	Процедура возвращает кол-во блокнотов на работа.юэй с признаками платности по 
--				публикациям и горячим, кол-во блокнотов на ворке.юэй с признаком "бизнес-размещение"
--				и разрыв (GAP) между двумя ресурсами за последние 12 недель
-- ======================================================================================================

DECLARE @PeriodNumber TINYINT = 12;

WITH C AS
 (
SELECT DD.YearNum, DD.WeekName, DD.WeekNum, DD.Date_key, COUNT(*) AS CompanyNum, SUM(FSCI.VacancyCount) AS VacancyNum
FROM dbo.DimSpiderCompany DSC
 JOIN dbo.FactSpiderCompanyIndexes FSCI ON DSC.SpiderCompanyID = FSCI.SpiderCompanyID
 JOIN dbo.DimDate DD ON FSCI.Date_key = DD.Date_key
WHERE DSC.SpiderSource_key = 1
 AND FSCI.IsBusiness IS NOT NULL
 AND FSCI.IsBusiness = 1
 AND DD.WeekDayNum = 6
GROUP BY DD.YearNum, DD.WeekName, DD.WeekNum, DD.Date_key
 )
 , C2 AS
 (
SELECT * 
 , (SELECT COUNT(*)
	FROM dbo.FactCompanyStatuses FCS
	WHERE FCS.Date_key = C.Date_key
	 AND (FCS.HasPaidPublishedVacs = 1 OR FCS.HasPaidPublicationsLeft = 1 OR FCS.HasHotPublishedVacs = 1 OR FCS.HasHotPublicationsLeft = 1)) AS PaidRabotaCompanyNum
FROM C
 )
 , C_Result AS
 (
SELECT YearNum, WeekNum, WeekName
 , 1. * (PaidRabotaCompanyNum - CompanyNum) / dbo.fnGetMinimumOf2Values(PaidRabotaCompanyNum, CompanyNum) AS GapCompany
 , PaidRabotaCompanyNum
 , CompanyNum
 , ROW_NUMBER() OVER(ORDER BY YearNum DESC, WeekNum DESC) AS RowNum
FROM C2
 )
SELECT *
FROM C_Result
WHERE RowNum BETWEEN 1 AND @PeriodNumber;