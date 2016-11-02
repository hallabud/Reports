
CREATE PROCEDURE [dbo].[usp_etl_FactRemainService]

AS

BEGIN

DECLARE @ReportDT DATETIME; SET @ReportDT = dbo.fnGetDatePart(GETDATE());

DECLARE @Date_key INT;
SELECT @Date_key = Date_key FROM Reporting.dbo.DimDate WHERE FullDate = @ReportDT;

--1	Standard
--2	Professional
--3	VIP
--4	Анонимная
--5	Базовая вакансия
--6	Hot
--7	CVDB
--8	Company Profile
--9	Logotype

INSERT INTO Reporting.dbo.FactRemainService
SELECT
   @Date_key AS Date_key
 , Service_key
 , CAST(SUM(SummUnused) AS DECIMAL(12,2)) AS SummUnused
FROM
 (
-- Standard
SELECT 
   1 AS Service_key
 , Id
 , AddDate
 , CAST(SummStandart / 1.2 * (VacancyStandart - dbo.fnGetTicketSpendCountAtTime(TP.Id, 1, @ReportDT)) / VacancyStandart AS DECIMAL(12,2)) AS SummUnused
FROM SRV16.RabotaUA2.dbo.TicketPayment TP 
WHERE TP.AddDate <= @ReportDT + 1
 AND TP.ExpiryDate >= @ReportDT
 AND TP.SummStandart > 0
 AND TP.VacancyStandart > 0
 AND TP.TicketPaymentTypeID IN (1,2,3,4)

UNION ALL

-- Professional
SELECT 
   2 AS Service_key
 , Id
 , AddDate
 , CAST(SummDesigned / 1.2 * (VacancyDesigned - dbo.fnGetTicketSpendCountAtTime(TP.Id, 2, @ReportDT)) / VacancyDesigned AS DECIMAL(12,2)) AS SummUnused
FROM SRV16.RabotaUA2.dbo.TicketPayment TP 
WHERE TP.AddDate <= @ReportDT + 1
 AND TP.ExpiryDate >= @ReportDT
 AND TP.SummDesigned > 0
 AND TP.VacancyDesigned > 0
 AND TP.TicketPaymentTypeID IN (1,2,3,4)

UNION ALL

-- Vip
SELECT 
   3 AS Service_key
 , Id
 , AddDate
 , CAST(SummVip / 1.2 * (VacancyVip - dbo.fnGetTicketSpendCountAtTime(TP.Id, 3, @ReportDT)) / VacancyVip AS DECIMAL(12,2)) AS SummUnused
FROM SRV16.RabotaUA2.dbo.TicketPayment TP 
WHERE TP.AddDate <= @ReportDT + 1
 AND TP.ExpiryDate >= @ReportDT
 AND TP.SummVip > 0
 AND TP.VacancyVip > 0
 AND TP.TicketPaymentTypeID IN (1,2,3,4)

UNION ALL

-- Hot
SELECT 
   6 AS Service_key
 , Id
 , AddDate
 , CAST(SummHot / 1.2 * (VacancyHot - dbo.fnGetTicketSpendCountAtTime(TP.Id, 5, @ReportDT)) / VacancyHot AS DECIMAL(12,2)) AS SummUnused
FROM SRV16.RabotaUA2.dbo.TicketPayment TP 
WHERE TP.AddDate <= @ReportDT + 1
 AND TP.ExpiryDate >= @ReportDT
 AND TP.SummHot > 0
 AND TP.VacancyHot > 0
 AND TP.TicketPaymentTypeID IN (1,2,3,4)

UNION ALL

-- Anonym
SELECT 
   4 AS Service_key
 , RTP.Id
 , dbo.fnDateByDay(RTP.DatePayment)
 , CAST(RTP.TicketSumm / 1.2 * (RTP.TicketCount - dbo.fnGetRegionalTicketSpendCountAtTime(RTP.Id, 16, @ReportDT)) / RTP.TicketCount AS DECIMAL(12,2)) AS SummUnused
FROM SRV16.RabotaUA2.dbo.RegionalTicketPayment RTP
WHERE PackageId = 16
  AND RTP.TicketPaymentTypeID IN (1,2,3,4)
  AND RTP.TicketSumm > 0
  AND RTP.TicketCount > 0
  AND dbo.fnDateByDay(RTP.DatePayment) <= @ReportDT
  AND dbo.fnDateByDay(RTP.DateValid) >= @ReportDT

UNION ALL

-- Basic
SELECT 
   5 AS Service_key
 , RTP.Id
 , dbo.fnDateByDay(RTP.DatePayment)
 , CAST(RTP.TicketSumm / 1.2 * (RTP.TicketCount - dbo.fnGetRegionalTicketSpendCountAtTime(RTP.Id, 18, @ReportDT)) / RTP.TicketCount AS DECIMAL(12,2)) AS SummUnused
FROM SRV16.RabotaUA2.dbo.RegionalTicketPayment RTP
WHERE PackageId = 18
  AND RTP.TicketPaymentTypeID IN (1,2,3,4)
  AND RTP.TicketSumm > 0
  AND RTP.TicketCount > 0
  AND dbo.fnDateByDay(RTP.DatePayment) <= @ReportDT
  AND dbo.fnDateByDay(RTP.DateValid) >= @ReportDT

UNION ALL

-- CVDB
SELECT
   7 AS Service_key
 , TmP.Id
 , Tmp.StartDate
 , CAST(ISNULL((Price * DATEDIFF(DAY, @ReportDT, EndDate) / DATEDIFF(DAY, StartDate, EndDate)),0.00) AS DECIMAL(10,2)) AS SummUnused
FROM SRV16.RabotaUA2.dbo.TemporalPayment TmP
WHERE StartDate <= @ReportDT
 AND EndDate >= @ReportDT
 AND NotebookPaymentStateID = 1
 AND Price > 0
 AND DATEDIFF(DAY, StartDate, EndDate) > 0

UNION ALL

--8	Company Profile
SELECT
   8 AS Service_key
 , OD.ID
 , ActivationStartDate
 , CAST(ISNULL((ClientPrice * Datediff(Day, @ReportDT, ActivationEndDate) / Datediff(Day, ActivationStartDate, ActivationEndDate)),0.00) AS DECIMAL(10,2)) AS SummUnused
FROM SRV16.RabotaUA2.dbo.OrderDetail OD
WHERE OD.State IN (2,3)
 AND OD.ActivationStartDate <= @ReportDT
 AND OD.ActivationEndDate >= @ReportDT
 AND OD.ServiceID IN (25,26)
 AND OD.ClientPrice > 0
 AND Datediff(Day, ActivationStartDate, ActivationEndDate) > 0

--9	Logotype
UNION ALL

SELECT
   9 AS Service_key
 , OD.ID
 , ActivationStartDate
 , CAST(ISNULL((ClientPrice * Datediff(Day, @ReportDT, ActivationEndDate) / Datediff(Day, ActivationStartDate, ActivationEndDate)),0.00) AS DECIMAL(10,2))
FROM SRV16.RabotaUA2.dbo.OrderDetail OD
WHERE OD.State IN (2,3)
 AND OD.ActivationStartDate <= @ReportDT
 AND OD.ActivationEndDate >= @ReportDT
 AND OD.ServiceID BETWEEN 27 AND 46
 AND OD.ClientPrice > 0
 AND Datediff(Day, ActivationStartDate, ActivationEndDate) > 0

 ) t1
GROUP BY Service_key

END
;