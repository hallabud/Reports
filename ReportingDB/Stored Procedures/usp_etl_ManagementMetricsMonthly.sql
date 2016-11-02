
CREATE PROCEDURE [dbo].[usp_etl_ManagementMetricsMonthly]

AS

BEGIN

	SET NOCOUNT ON;

	SET DATEFIRST 1;

	DECLARE @StartDate DATETIME;
	DECLARE @EndDate DATETIME;
	DECLARE @YearNum INT;
	DECLARE @MonthNum INT;
	DECLARE @MonthName VARCHAR(15);

	SET @YearNum = DATEPART(YEAR, GETDATE() - 1);
	SET @MonthNum = DATEPART(MONTH, GETDATE() - 1);

	SELECT @StartDate = FirstMonthDate FROM dbo.DimDate WHERE YearNum = @YearNum AND MonthNum = @MonthNum;
	SELECT @EndDate = LastMonthDate FROM dbo.DimDate WHERE YearNum = @YearNum AND MonthNum = @MonthNum;
	SELECT @MonthName = MonthNameRus FROM dbo.DimDate WHERE YearNum = @YearNum AND MonthNum = @MonthNum;

	---------------------------------------
	-- Отчетная дата
	---------------------------------------
	INSERT INTO dbo.AggrManagementMetricsMonthly(YearNum, MonthNum, [MonthName]) VALUES (@YearNum, @MonthNum, @MonthName)

	---------------------------------------
	-- Кол-во откликов
	---------------------------------------
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
		WHERE VATV.AddDate BETWEEN @StartDate AND @EndDate + 1

		UNION ALL
		-- отклики проф. резюме
		SELECT
		   RTV.AddDate
		 , RTV.Email
		FROM SRV16.RabotaUA2.dbo.ResumeToVacancy RTV WITH (NOLOCK)
		WHERE RTV.AddDate BETWEEN @StartDate AND @EndDate + 1

		UNION ALL
		-- отклики аттачем повнорные (одного и того же соискателя на одну и ту же вакансию)
		SELECT
		   MEM.OldAddDate AS AddDate
		 , VA.Email
		FROM SRV16.RabotaUA2.dbo.ResumeAttachToVacancy_Memory MEM WITH (NOLOCK)
		 JOIN SRV16.RabotaUA2.dbo.VacancyApplyToVacancy VATV WITH (NOLOCK) ON MEM.MemoryID = VATV.ID AND MEM.IsAttach = 1
		 JOIN SRV16.RabotaUA2.dbo.VacancyApplyCVs VACV WITH (NOLOCK) ON VATV.VacancyApplyCVsID = VACV.ID
		 JOIN SRV16.RabotaUA2.dbo.VacancyApply VA WITH (NOLOCK) ON VACV.VacancyApplyID = VA.ID
		WHERE MEM.OldAddDate BETWEEN @StartDate AND @EndDate + 1

		UNION ALL
		-- отклики проф.резюме повнорные (одного и того же соискателя на одну и ту же вакансию)
		SELECT
		   MEM.OldAddDate AS AddDate
		 , RTV.Email
		FROM SRV16.RabotaUA2.dbo.ResumeAttachToVacancy_Memory MEM WITH (NOLOCK)
		 JOIN SRV16.RabotaUA2.dbo.ResumeToVacancy RTV WITH (NOLOCK) ON MEM.MemoryID = RTV.ID AND MEM.ISAttach = 0
		WHERE MEM.OldAddDate BETWEEN @StartDate AND @EndDate + 1
	 ) Resp 

	UPDATE dbo.AggrManagementMetricsMonthly 
	SET ResponsesNum = @Responses
	WHERE YearNum = @YearNum AND MonthNum = @MonthNum;

	---------------------------------------
	-- Кол-во просмотренных откликов 
	---------------------------------------
	
	IF OBJECT_ID('tempdb..#ResponsesViewed','U') IS NOT NULL DROP TABLE #ResponsesViewed;

	CREATE TABLE #ResponsesViewed
		(FullDate DATE, ResponseViewSource VARCHAR(8));

	INSERT INTO #ResponsesViewed
	SELECT Reporting.dbo.fnGetDatePart(AddDate) AS FullDate
	 , CASE 
		WHEN VATV.IsViewedFromLetter = 1 THEN 'E-mail'
		ELSE 'Notebook'
	   END AS ResponseViewSource
	FROM SRV16.RabotaUA2.dbo.VacancyApplyToVacancy VATV WITH (NOLOCK)
	WHERE VATV.AddDate BETWEEN @StartDate AND @EndDate + 1
	 AND VATV.ViewedDate IS NOT NULL
 
	UNION ALL

	SELECT Reporting.dbo.fnGetDatePart(RTV.AddDate) AS FullDate
	 , CASE 
		WHEN RTV.IsViewedFromLetter = 1 THEN 'E-mail'
		ELSE 'Notebook'
	   END AS ResponseViewSource
	FROM SRV16.RabotaUA2.dbo.ResumeToVacancy RTV WITH (NOLOCK)
	WHERE RTV.AddDate BETWEEN @StartDate AND @EndDate + 1
	 AND RTV.ViewedDate IS NOT NULL;

	DECLARE @ResponsesViewed INT = (SELECT COUNT(*) FROM #ResponsesViewed);

	UPDATE dbo.AggrManagementMetricsMonthly 
	SET ResponsesNum_Viewed = @ResponsesViewed
	WHERE YearNum = @YearNum AND MonthNum = @MonthNum;

	DROP TABLE #ResponsesViewed;

	--------------------------------------------------------
	-- Кол-во емейлов, подписанных хотя бы на 1 job-alert --
	--------------------------------------------------------
	
	DECLARE @SubscribeCompetitorEmailCount INT = (SELECT COUNT(DISTINCT UserEMail) 
												  FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor WITH (NOLOCK)
												  WHERE IsActive = 1
												   AND CompanyNotebookID IS NULL);

	UPDATE dbo.AggrManagementMetricsMonthly 
	SET SubscribeCompetitor_EmailCount = @SubscribeCompetitorEmailCount
	WHERE YearNum = @YearNum AND MonthNum = @MonthNum;

	------------------------------------------------------------------
	-- Кол-во новых полученных емейлов, из них с резюме и откликами --
	------------------------------------------------------------------

		DECLARE @MonthStartDate DATETIME = (SELECT FirstMonthDate FROM Reporting.dbo.DimDate WHERE FullDate = dbo.fnGetDatePart(DATEADD(MONTH, -1, GETDATE())));
		DECLARE @MonthStartDay INT = dbo.fnDayBydate(@MonthStartDate);
		DECLARE @MonthEndDate DATETIME = (SELECT LastMonthDate FROM Reporting.dbo.DimDate WHERE FullDate = dbo.fnGetDatePart(DATEADD(MONTH, -1, GETDATE())));
		DECLARE @MonthEndDay INT = dbo.fnDayBydate(@MonthEndDate);

		IF OBJECT_ID('tempdb..#EmailList','U') IS NOT NULL DROP TABLE #EmailList;
		IF OBJECT_ID('tempdb..#EmailListDetails','U') IS NOT NULL DROP TABLE #EmailListDetails;

		-- ------------------------------------------------
		-- Временная таблица для хранения списка емейлов --
		-- ------------------------------------------------

		SELECT ES.Email, ES.AddDate, dbo.fnDayByDate(ES.AddDate) AS AddDay, DATEADD(WEEK, 2, ES.AddDate) AS AddDate14, dbo.fnDayByDate(DATEADD(WEEK, 2, ES.AddDate)) AS AddDay14
		INTO #EmailList
		FROM Analytics.dbo.EmailSource ES
		WHERE AddDate BETWEEN @MonthStartDate AND @MonthEndDate + 1;

		-- -----------------------------------------------------------------------------
		-- Временная таблица для хранения списка емейлов c рассчитанными показателями --
		-- -----------------------------------------------------------------------------

		SELECT 
		   Email
		 , (SELECT COUNT(*) FROM Analytics.dbo.ResumeToVacancy RTV WHERE RTV.EMail = EL.Email AND RTV.AddDate BETWEEN EL.AddDate AND EL.AddDate14) 
			+ (SELECT COUNT(*) 
			   FROM Analytics.dbo.VacancyApplyToVacancy VATV
				JOIN Analytics.dbo.VacancyApplyCVs VACV ON VATV.VacancyApplyCVsID = VACV.ID
				JOIN Analytics.dbo.VacancyApply VA ON VACV.VacancyApplyID = VA.ID
			   WHERE VA.EMail = EL.Email
				AND VATV.AddDate BETWEEN EL.AddDate AND EL.AddDate14) AS ResponsesCount
		 , CASE WHEN EXISTS (SELECT * 
							 FROM Analytics.dbo.ResumeStateHistory RSH 
							  JOIN Analytics.dbo.Resume R ON RSH.ResumeId = R.ID 
							 WHERE EL.Email = R.Email 
							  AND RSH.State = 1
							  AND (RSH.DateFrom BETWEEN EL.AddDay AND EL.AddDay14 OR RSH.DateTo BETWEEN AddDay AND EL.AddDay14)) THEN 1 ELSE 0 END AS HasPublishedResume
		INTO #EmailListDetails
		FROM #EmailList EL;


		UPDATE Reporting.dbo.AggrManagementMetricsMonthly
		SET EmailsAcquired = (SELECT COUNT(*) FROM #EmailListDetails)
		  , EmailsAcquired_HasCvPublished = (SELECT COUNT(*) FROM #EmailListDetails WHERE ResponsesCount >= 1)
		  , EmailsAcquired_HasCvPublishedOrApplied = (SELECT COUNT(*) FROM #EmailListDetails WHERE HasPublishedResume = 1 OR ResponsesCount >= 1)
		WHERE YearNum = @YearNum AND MonthNum = @MonthNum;

		DROP TABLE #EmailList;
		DROP TABLE #EmailListDetails;

END
