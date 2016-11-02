CREATE PROCEDURE dbo.usp_etl_ManagementMetricsDaily  
	@ReportDate DATETIME

 AS

DECLARE @Responses INT;

SELECT 
  @Responses = COUNT(*)
FROM 
 (
	SELECT
	   VATV.AddDate
	 , VA.EMail
	FROM SRV16.RabotaUA2.dbo.VacancyApplyToVacancy VATV WITH (NOLOCK)
	 JOIN SRV16.RabotaUA2.dbo.VacancyApplyCVs VACV WITH (NOLOCK) ON VATV.VacancyApplyCVsID = VACV.ID
	 JOIN SRV16.RabotaUA2.dbo.VacancyApply VA WITH (NOLOCK) ON VACV.VacancyApplyID = VA.ID
	WHERE VATV.AddDate BETWEEN @ReportDate AND @ReportDate + 1

	UNION ALL
	-- отклики проф. резюме
	SELECT
	   RTV.AddDate
	 , RTV.Email
	FROM SRV16.RabotaUA2.dbo.ResumeToVacancy RTV WITH (NOLOCK)
	WHERE RTV.AddDate BETWEEN @ReportDate AND @ReportDate + 1

	UNION ALL
	-- отклики аттачем повнорные (одного и того же соискателя на одну и ту же вакансию)
	SELECT
	   MEM.OldAddDate AS AddDate
	 , VA.Email
	FROM SRV16.RabotaUA2.dbo.ResumeAttachToVacancy_Memory MEM WITH (NOLOCK)
	 JOIN SRV16.RabotaUA2.dbo.VacancyApplyToVacancy VATV WITH (NOLOCK) ON MEM.MemoryID = VATV.ID AND MEM.IsAttach = 1
	 JOIN SRV16.RabotaUA2.dbo.VacancyApplyCVs VACV WITH (NOLOCK) ON VATV.VacancyApplyCVsID = VACV.ID
	 JOIN SRV16.RabotaUA2.dbo.VacancyApply VA WITH (NOLOCK) ON VACV.VacancyApplyID = VA.ID
	WHERE MEM.OldAddDate BETWEEN @ReportDate AND @ReportDate + 1

	UNION ALL
	-- отклики проф.резюме повнорные (одного и того же соискателя на одну и ту же вакансию)
	SELECT
	   MEM.OldAddDate AS AddDate
	 , RTV.Email
	FROM SRV16.RabotaUA2.dbo.ResumeAttachToVacancy_Memory MEM WITH (NOLOCK)
	 JOIN SRV16.RabotaUA2.dbo.ResumeToVacancy RTV WITH (NOLOCK) ON MEM.MemoryID = RTV.ID AND MEM.ISAttach = 0
	WHERE MEM.OldAddDate BETWEEN @ReportDate AND @ReportDate + 1
 ) Resp 


DECLARE @ResponsesViewed INT;

SELECT 
   @ResponsesViewed = COUNT(*)
FROM 
 (
	SELECT
	   VATV.ID
	FROM SRV16.RabotaUA2.dbo.VacancyApplyToVacancy VATV WITH (NOLOCK)
	WHERE VATV.AddDate BETWEEN @ReportDate AND @ReportDate + 1
	 AND VATV.ViewedDate IS NOT NULL

	UNION ALL
	-- отклики проф. резюме
	SELECT
	   RTV.ID
	FROM SRV16.RabotaUA2.dbo.ResumeToVacancy RTV WITH (NOLOCK)
	WHERE RTV.AddDate BETWEEN @ReportDate AND @ReportDate + 1
	 AND RTV.ViewedDate IS NOT NULL

	UNION ALL
	-- отклики аттачем повнорные (одного и того же соискателя на одну и ту же вакансию)
	SELECT
	   MEM.ID AS AddDate
	FROM SRV16.RabotaUA2.dbo.ResumeAttachToVacancy_Memory MEM WITH (NOLOCK)
	 JOIN SRV16.RabotaUA2.dbo.VacancyApplyToVacancy VATV WITH (NOLOCK) ON MEM.MemoryID = VATV.ID AND MEM.IsAttach = 1
	WHERE MEM.OldAddDate BETWEEN @ReportDate AND @ReportDate + 1
	 AND VATV.ViewedDate IS NOT NULL

	UNION ALL
	-- отклики проф.резюме повнорные (одного и того же соискателя на одну и ту же вакансию)
	SELECT
	   MEM.ID
	FROM SRV16.RabotaUA2.dbo.ResumeAttachToVacancy_Memory MEM WITH (NOLOCK)
	 JOIN SRV16.RabotaUA2.dbo.ResumeToVacancy RTV WITH (NOLOCK) ON MEM.MemoryID = RTV.ID AND MEM.ISAttach = 0
	WHERE MEM.OldAddDate BETWEEN @ReportDate AND @ReportDate + 1
	 AND RTV.ViewedDate IS NOT NULL
 ) Resp 

INSERT INTO Reporting.dbo.AggrManagementMetricsDaily
SELECT @ReportDate, @Responses, @ResponsesViewed;

