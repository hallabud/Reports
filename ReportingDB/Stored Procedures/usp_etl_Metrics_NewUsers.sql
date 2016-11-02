CREATE PROCEDURE [dbo].[usp_etl_Metrics_NewUsers] 
	@Today DATETIME

AS

SET DATEFIRST 1;    

DECLARE @Week0_Start DATETIME = DATEADD(WEEK, -3, Analytics.dbo.fnGetDatePart(DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today)));
DECLARE @Week1_Start DATETIME = DATEADD(WEEK, 1, @Week0_Start);
DECLARE @Week2_Start DATETIME = DATEADD(WEEK, 2, @Week0_Start);
DECLARE @Week3_Start DATETIME = DATEADD(WEEK, 3, @Week0_Start);

DECLARE @Week0_Start_Day INT = Analytics.dbo.fnDayByDate(@Week0_Start);
DECLARE @Week1_Start_Day INT = Analytics.dbo.fnDayByDate(@Week1_Start);
DECLARE @Week2_Start_Day INT = Analytics.dbo.fnDayByDate(@Week2_Start);
DECLARE @Week3_Start_Day INT = Analytics.dbo.fnDayByDate(@Week3_Start);

DECLARE @ReportYear INT;
SELECT @ReportYear = YearNum FROM Reporting.dbo.DimDate WHERE FullDate = @Week0_Start;

DECLARE @ReportWeekName VARCHAR(100);
SELECT @ReportWeekName = WeekName FROM Reporting.dbo.DimDate WHERE FullDate = @Week0_Start;

DECLARE @ReportWeekNum INT;
SELECT @ReportWeekNum = WeekNum FROM Reporting.dbo.DimDate WHERE FullDate = @Week0_Start;


-- ------------------------------------------------
-- Временная таблица для хранения списка емейлов --
-- ------------------------------------------------
IF OBJECT_ID('tempdb..#EmailList','U') IS NOT NULL DROP TABLE #EmailList;
IF OBJECT_ID('tempdb..#EmailListDetails','U') IS NOT NULL DROP TABLE #EmailListDetails;

SELECT
   ES.Email
 , CASE 
    WHEN CP.Name = 'Регистрация блокнота при добавлении резюме' THEN 'Registration With Create CV'
	WHEN CP.Name = 'Отправка резюме и подписка на вакансию' THEN 'Apply + Job Alert'
	WHEN CP.Name = 'Регистрация блокнота соискателя со страницы регистрации' THEN 'Registration Only'
	WHEN CP.Name = 'Отправка резюме' THEN 'Apply - Job Alert'
	WHEN CP.Name = 'Подписка на вакансии со страницы результата поиска' THEN 'Search Results Job Alert'
	WHEN CP.Name IN ('Подписка на вакансии компании с профиля компании','Подписка на вакансии компании со страницы вакансии') THEN 'Company Job Alert'
	WHEN CP.Name IN ('Подписка на похожие вакансии со страницы вакансии','Подписка на похожие вакансии со страницы вакансии (верх)') THEN 'Similar Vacancies Job Alert'
   END AS ConversionSource
INTO #EmailList
FROM Analytics.dbo.EmailSource ES
 JOIN Analytics.dbo.Dir_ConversionPage CP ON ES.ConversionPageID = CP.ID
WHERE AddDate BETWEEN @Week0_Start AND @Week1_Start
 AND CP.Identifier IN ('/got_new_email_apply_and_alert',
					   '/got_new_email_apply',
					   '/got_new_email_alert_vacancypage',
					   '/got_new_email_alert_vacancypage_top',
					   '/got_new_email_companyalert_profile',
					   '/got_new_email_companyalert_vacancypage',
					   '/got_new_email_alert_searchresultpage',
					   '/got_new_email_register_registerpage',
					   '/got_new_email_register_addcv');

-- -----------------------------------------------------------------------------
-- Временная таблица для хранения списка емейлов c рассчитанными показателями --
-- -----------------------------------------------------------------------------

SELECT 
   ConversionSource
 , Email
 , CASE WHEN EXISTS (SELECT * 
					 FROM Analytics.dbo.NotebookEmployee NE WITH (NOLOCK)
					  JOIN Analytics.dbo.Notebook N WITH (NOLOCK) ON NE.NotebookId = N.Id
					  JOIN Analytics.dbo.aspnet_Membership M WITH (NOLOCK) ON N.aspnet_UserUIN = M.UserId
					 WHERE EL.EMail = M.Email
					  AND M.CreateDate BETWEEN @Week0_Start AND @Week3_Start) THEN 1 ELSE 0 END AS HasNotebookRegistration
 , CASE WHEN EXISTS (SELECT * FROM Analytics.dbo.SubscribeCompetitor SC WITH (NOLOCK) WHERE SC.UserEMail = EL.EMail AND SC.AddDate BETWEEN @Week0_Start AND @Week3_Start) THEN 1 ELSE 0 END AS HasSubscribedOnJA
 , CASE WHEN EXISTS (SELECT * FROM Analytics.dbo.SubscribeCompetitor SC WITH (NOLOCK) WHERE SC.UserEMail = EL.EMail AND (SC.LastViewDate BETWEEN @Week0_Start AND @Week3_Start OR SC.LastViewPictureDate BETWEEN @Week0_Start AND @Week3_Start)) THEN 1 ELSE 0 END AS HasViewOrVisitFromJA
 , CASE WHEN EXISTS (SELECT * FROM Analytics.dbo.SubscribeCompetitor SC WITH (NOLOCK) WHERE SC.UserEMail = EL.EMail AND SC.LastViewDate BETWEEN @Week0_Start AND @Week3_Start) THEN 1 ELSE 0 END AS HasVisitFromJA
 , (SELECT COUNT(*) FROM Analytics.dbo.ResumeToVacancy RTV WHERE RTV.EMail = EL.Email AND RTV.AddDate BETWEEN @Week0_Start AND @Week3_Start) 
    + (SELECT COUNT(*) 
	   FROM Analytics.dbo.VacancyApplyToVacancy VATV
		JOIN Analytics.dbo.VacancyApplyCVs VACV ON VATV.VacancyApplyCVsID = VACV.ID
		JOIN Analytics.dbo.VacancyApply VA ON VACV.VacancyApplyID = VA.ID
	   WHERE VA.EMail = EL.Email
	    AND VATV.AddDate BETWEEN @Week0_Start AND @Week3_Start) AS ResponsesCount
 , CASE WHEN EXISTS (SELECT * FROM Analytics.dbo.Resume R WHERE R.Email = EL.Email AND R.State = 1) THEN 1 ELSE 0 END AS HasActiveResume
 , CASE WHEN EXISTS (SELECT * 
					 FROM Analytics.dbo.ResumeStateHistory RSH 
					  JOIN Analytics.dbo.Resume R ON RSH.ResumeId = R.ID 
					 WHERE EL.Email = R.Email 
					  AND RSH.State = 1
					  AND (RSH.DateFrom BETWEEN @Week0_Start_Day AND @Week3_Start OR RSH.DateTo BETWEEN @Week0_Start_Day AND @Week3_Start_Day)) THEN 1 ELSE 0 END AS HasPublishedResume
 , CASE WHEN EXISTS (SELECT * FROM Analytics.dbo.Resume R WHERE R.Email = EL.Email AND CAST(R.UpdateDate AS DATE) > CAST(AddDate AS DATE)) THEN 1 ELSE 0 END AS HasUpdatedResume
INTO #EmailListDetails
FROM #EmailList EL;

WITH C AS
 (
SELECT @ReportYear AS YearNum, @ReportWeekNum AS WeekNum, @ReportWeekName AS WeekName, ConversionSource, 'Всего новых пользователей' AS MetricName, COUNT(*) AS MetricValue
FROM #EmailListDetails ELDr
GROUP BY ConversionSource

UNION ALL

SELECT @ReportYear, @ReportWeekNum, @ReportWeekName, ConversionSource, 'Пользователей, которые зарегистрировались', COUNT(*) AS MetricValue
FROM #EmailListDetails ELDr
WHERE HasNotebookRegistration = 1
GROUP BY ConversionSource

UNION ALL

SELECT @ReportYear, @ReportWeekNum, @ReportWeekName, ConversionSource, 'Пользователей, которые подписались хотя бы на один Job Alert', COUNT(*) AS MetricValue
FROM #EmailListDetails ELDr
WHERE HasSubscribedOnJA = 1
GROUP BY ConversionSource

UNION ALL

SELECT @ReportYear, @ReportWeekNum, @ReportWeekName, ConversionSource, 'Пользователей, у которых был хоть один визит или просмотр из Job Alert', COUNT(*) AS MetricValue
FROM #EmailListDetails ELDr
WHERE HasViewOrVisitFromJA = 1
GROUP BY ConversionSource

UNION ALL

SELECT @ReportYear, @ReportWeekNum, @ReportWeekName, ConversionSource, 'Пользователей, у которых был хоть один визит из Job Alert', COUNT(*) AS MetricValue
FROM #EmailListDetails ELDr
WHERE HasVisitFromJA = 1
GROUP BY ConversionSource

UNION ALL 

SELECT @ReportYear, @ReportWeekNum, @ReportWeekName, ConversionSource, 'Пользователей, отправлявших резюме хотя бы 1 раз', COUNT(*) AS MetricValue
FROM #EmailListDetails ELDr
WHERE ResponsesCount >= 1
GROUP BY ConversionSource

UNION ALL 

SELECT @ReportYear, @ReportWeekNum, @ReportWeekName, ConversionSource, 'Пользователей, отправлявших резюме хотя бы 2 раза', COUNT(*) AS MetricValue
FROM #EmailListDetails ELDr
WHERE ResponsesCount >= 2
GROUP BY ConversionSource

UNION ALL

SELECT @ReportYear, @ReportWeekNum, @ReportWeekName, ConversionSource, 'Пользователей с активными резюме', COUNT(*) AS MetricValue
FROM #EmailListDetails ELDr
WHERE HasActiveResume = 1
GROUP BY ConversionSource

UNION ALL

SELECT @ReportYear, @ReportWeekNum, @ReportWeekName, ConversionSource, 'Пользователей с резюме, которое было опубликовано хотя бы один раз', COUNT(*) AS MetricValue
FROM #EmailListDetails ELDr
WHERE HasPublishedResume = 1
GROUP BY ConversionSource

UNION ALL

SELECT @ReportYear, @ReportWeekNum, @ReportWeekName, ConversionSource, 'Количество откликов', SUM(ResponsesCount) AS MetricValue
FROM #EmailListDetails ELDr
GROUP BY ConversionSource

UNION ALL

SELECT @ReportYear, @ReportWeekNum, @ReportWeekName, ConversionSource, 'Пользователей с резюме, которое было обновлено хотя бы один раз', COUNT(*) AS MetricValue
FROM #EmailListDetails ELDr
WHERE HasUpdatedResume = 1
GROUP BY ConversionSource
 )

INSERT INTO Reporting.dbo.FactMetricsNewUsers
SELECT C.YearNum, C.WeekNum, C.WeekName, LM.MetricID, LCS.ConversionSourceID, C.MetricValue 
FROM C
 JOIN Reporting.dbo.Lookup_Metrics LM ON C.MetricName = LM.MetricName
 JOIN Reporting.dbo.Lookup_ConversionSource LCS ON C.ConversionSource = LCS.ConversionSourceName
;

