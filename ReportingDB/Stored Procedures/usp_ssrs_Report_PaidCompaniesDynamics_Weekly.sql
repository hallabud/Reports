--DECLARE @StartDate DATETIME = '2015-10-01';
--DECLARE @EndDate DATETIME = '2015-11-27';


CREATE PROCEDURE [dbo].[usp_ssrs_Report_PaidCompaniesDynamics_Weekly]

AS

DECLARE @StartDateKey INT = (SELECT Date_key FROM dbo.DimDate WHERE FullDate = DATEADD(MONTH, -3, CAST(GETDATE() AS DATE)))

SELECT DD.YearNum, DD.WeekNum, DD.WeekName, PS.PaymentStatus, COUNT(DISTINCT Company_key) AS CompanyCount
FROM dbo.FactCompanyStatuses FCS
 JOIN dbo.DimPaymentStatus PS ON FCS.PaymentStatusKey = PS.PaymentStatusKey
 JOIN dbo.DimDate DD ON FCS.Date_key = DD.Date_key
WHERE FCS.PaymentStatusKey IS NOT NULL
 AND FCS.Date_key >= @StartDateKey
GROUP BY DD.YearNum, DD.WeekNum, DD.WeekName, PS.PaymentStatusKey, PS.PaymentStatus
ORDER BY DD.YearNum, DD.WeekNum, DD.WeekName, PS.PaymentStatusKey;