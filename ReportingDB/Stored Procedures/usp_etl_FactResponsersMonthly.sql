CREATE PROCEDURE [dbo].[usp_etl_FactResponsersMonthly]

AS

DECLARE @StartDate DATETIME;
DECLARE @EndDate DATETIME;

DECLARE @ReportYear SMALLINT;
SET @ReportYear = DATEPART(YEAR, DATEADD(DAY, -1, GETDATE()));

DECLARE @ReportMonth TINYINT;
SET @ReportMonth = DATEPART(MONTH, DATEADD(DAY, -1, GETDATE()));

SELECT @StartDate = MIN(FullDate) FROM Reporting.dbo.DimDate WHERE YearNum = @ReportYear AND MonthNum = @ReportMonth;
SELECT @EndDate = DATEADD(DAY, 1, MAX(FullDate)) FROM Reporting.dbo.DimDate WHERE YearNum = @ReportYear AND MonthNum = @ReportMonth;

INSERT INTO Reporting.dbo.FactResponsers
SELECT @ReportYear, @ReportMonth, COUNT(DISTINCT EMail)
FROM 
 (
	SELECT
	   VATV.AddDate
	 , VA.EMail
	FROM SRV16.RabotaUA2.dbo.VacancyApplyToVacancy VATV
	 JOIN SRV16.RabotaUA2.dbo.VacancyApplyCVs VACV ON VATV.VacancyApplyCVsID = VACV.ID
	 JOIN SRV16.RabotaUA2.dbo.VacancyApply VA ON VACV.VacancyApplyID = VA.ID
	WHERE VATV.AddDate BETWEEN @StartDate AND @EndDate

	UNION ALL
	-- отклики проф. резюме
	SELECT
	   RTV.AddDate
	 , RTV.Email
	FROM SRV16.RabotaUA2.dbo.ResumeToVacancy RTV
	WHERE RTV.AddDate BETWEEN @StartDate AND @EndDate

	UNION ALL
	-- отклики аттачем повнорные (одного и того же соискателя на одну и ту же вакансию)
	SELECT
	   MEM.OldAddDate AS AddDate
	 , VA.Email
	FROM SRV16.RabotaUA2.dbo.ResumeAttachToVacancy_Memory MEM 
	 JOIN SRV16.RabotaUA2.dbo.VacancyApplyToVacancy VATV ON MEM.MemoryID = VATV.ID AND MEM.IsAttach = 1
	 JOIN SRV16.RabotaUA2.dbo.VacancyApplyCVs VACV ON VATV.VacancyApplyCVsID = VACV.ID
	 JOIN SRV16.RabotaUA2.dbo.VacancyApply VA ON VACV.VacancyApplyID = VA.ID
	WHERE MEM.OldAddDate BETWEEN @StartDate AND @EndDate

	UNION ALL
	-- отклики проф.резюме повнорные (одного и того же соискателя на одну и ту же вакансию)
	SELECT
	   MEM.OldAddDate AS AddDate
	 , RTV.Email
	FROM SRV16.RabotaUA2.dbo.ResumeAttachToVacancy_Memory MEM 
	 JOIN SRV16.RabotaUA2.dbo.ResumeToVacancy RTV ON MEM.MemoryID = RTV.ID AND MEM.ISAttach = 0
	WHERE MEM.OldAddDate BETWEEN @StartDate AND @EndDate
 ) Resp
