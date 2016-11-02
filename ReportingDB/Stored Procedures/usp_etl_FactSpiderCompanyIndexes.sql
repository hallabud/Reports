CREATE PROCEDURE [dbo].[usp_etl_FactSpiderCompanyIndexes]

AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @Date_key INT;
SELECT @Date_key = Date_key FROM dbo.DimDate WHERE FullDate = dbo.fnGetDatePart(GETDATE());

INSERT INTO dbo.FactSpiderCompanyIndexes (SpiderCompanyID, Date_key, VacancyCount, HotVacancyCount, Paid, IsPaidByTickets, IsHasLogo, IsBusiness, IsHasLogo_OnMain)
SELECT 
   DSC.SpiderCompanyID
 , @Date_key
 , ISNULL(SC.VacancyCount,0)
 , ISNULL(SC.HotVacancyCount,0)
 , ISNULL(SC.Paid, 0)
 , ISNULL(SC.IsPaidByTickets, 0)
 , ISNULL(SC.IsHasLogo, 0)
 , ISNULL(SC.IsBusiness, 0)
 , ISNULL(SC.IsHasLogo_OnMain, 0)
FROM SRV16.RabotaUA2.dbo.SpiderCompany SC
 JOIN dbo.DimSpiderCompany DSC ON SC.ID = DSC.SpiderCompanyID
WHERE SC.Source = 1;


-- временная таблица для сохранения последней даты, по состоянию на которую компания считалась платной на ворке
IF OBJECT_ID('tempdb..#T','U') IS NOT NULL DROP TABLE #T;

SELECT FSCI.SpiderCompanyID, DSC.CompanyID, MAX(DD.FullDate) AS LastIsPaidDate
INTO #T
FROM dbo.FactSpiderCompanyIndexes FSCI
 JOIN dbo.DimDate DD ON FSCI.Date_key = DD.Date_key
 JOIN dbo.DimSpiderCompany DSC ON FSCI.SpiderCompanyID = DSC.SpiderCompanyID
WHERE VacancyCount > 2 OR HotVacancyCount | Paid | IsPaidByTickets | IsHasLogo | IsBusiness | IsHasLogo_OnMain > 0
GROUP BY FSCI.SpiderCompanyID, DSC.CompanyID;

UPDATE DSC
SET LastIsPaidDate = T.LastIsPaidDate
FROM dbo.DimSpiderCompany DSC
 JOIN #T T ON DSC.SpiderCompanyID = T.SpiderCompanyID;
