
CREATE PROCEDURE [dbo].[usp_etl_ManagementMetricsWeekly]

AS

SET DATEFIRST 1;

DECLARE @StartDate DATETIME;
DECLARE @EndDate DATETIME;
DECLARE @WeekNum INT;
DECLARE @YearNum INT;
DECLARE @WeekName VARCHAR(15);

SET @YearNum = DATEPART(YEAR, GETDATE() - 1);
SET @WeekNum = DATEPART(WEEK, GETDATE() - 1);

SELECT @StartDate = FirstWeekDate FROM dbo.DimDate WHERE YearNum = @YearNum AND WeekNum = @WeekNum;
SELECT @EndDate = LastWeekDate FROM dbo.DimDate WHERE YearNum = @YearNum AND WeekNum = @WeekNum;
SELECT @WeekName = WeekName FROM dbo.DimDate WHERE YearNum = @YearNum AND WeekNum = @WeekNum;

---------------------------------------
-- Отчетная дата
---------------------------------------
INSERT INTO dbo.AggrManagementMetrics (YearNum, WeekNum, WeekName) VALUES (@YearNum, @WeekNum, @WeekName)

---------------------------------------
-- Кол-во открытий контактов в CVDB
---------------------------------------
DECLARE @OpenedContactsCount INT;
DECLARE @OpenedContactsCompanyCount INT;

SELECT @OpenedContactsCount = COUNT(*) FROM SRV16.RabotaUA2.dbo.DailyViewedResume WITH (NOLOCK) WHERE ViewDate BETWEEN @StartDate AND @EndDate;
SELECT @OpenedContactsCompanyCount = COUNT(DISTINCT EmployerNotebookID) FROM SRV16.RabotaUA2.dbo.DailyViewedResume WITH (NOLOCK) WHERE ViewDate BETWEEN @StartDate AND @EndDate;

UPDATE dbo.AggrManagementMetrics SET OpenedContacts_Count = @OpenedContactsCount, OpenedContacts_NotebookCount = @OpenedContactsCompanyCount WHERE YearNum = @YearNum AND WeekNum = @WeekNum;

---------------------------------------
-- Новые резюме на work.ua
---------------------------------------

DECLARE @Work_NewResume INT;

SELECT @Work_NewResume = Quantity
FROM SRV16.RabotaUA2.dbo.WorkVacancyResumeCount WITH (NOLOCK)
WHERE Type = 2 AND Date = Reporting.dbo.fnGetDatePart(GETDATE());

UPDATE dbo.AggrManagementMetrics SET Work_NewResumeCnt = @Work_NewResume WHERE YearNum = @YearNum AND WeekNum = @WeekNum;

---------------------------------------
-- Новые резюме на rabota.ua
---------------------------------------
DECLARE @Rabota_NewResume INT;

SELECT @Rabota_NewResume = COUNT(*)
FROM Reporting.dbo.DimDate DD
 JOIN SRV16.RabotaUA2.dbo.Resume R WITH (NOLOCK) ON DD.FullDate = Reporting.dbo.fnGetDatePart(R.AddDate)
WHERE DD.YearNum = @YearNum AND DD.WeekNum = @WeekNum
 AND R.State = 1
GROUP BY DD.YearNum, DD.WeekNum, DD.WeekName

UPDATE dbo.AggrManagementMetrics SET Rabota_NewResumeCnt = @Rabota_NewResume WHERE YearNum = @YearNum AND WeekNum = @WeekNum;

---------------------------------------
-- Новые вакансии на rabota.ua
---------------------------------------
DECLARE @Rabota_NewVacancy INT;

SELECT @Rabota_NewVacancy = COUNT(*)
FROM Reporting.dbo.DimDate DD
 JOIN SRV16.RabotaUA2.dbo.Vacancy V WITH (NOLOCK) ON DD.FullDate = Reporting.dbo.fnGetDatePart(V.AddDate)
 JOIN SRV16.RabotaUA2.dbo.VacancyExtra VE WITH (NOLOCK) ON V.ID = VE.VacancyID
WHERE DD.YearNum = @YearNum AND DD.WeekNum = @WeekNum
 AND VE.IsModerated = 1 AND VE.IsModeratedRubric = 1

UPDATE dbo.AggrManagementMetrics SET Rabota_NewVacancyCnt = @Rabota_NewVacancy WHERE YearNum = @YearNum AND WeekNum = @WeekNum;

---------------------------------------
-- Новые вакансии на work.ua
---------------------------------------
DECLARE @Work_NewVacancy INT;

DECLARE @VacancyMaxID INT
SELECT @VacancyMaxID = Vacancy_MaxID FROM SRV16.RabotaUA2.dbo.SpiderCompany_WorkStat WS WHERE WS.Date = DATEADD(DAY, -1, DATEADD(DAY, 1 - DATEPART(WEEKDAY, dbo.fnGetDatePart(GETDATE())),dbo.fnGetDatePart(GETDATE())));

DECLARE @VacancyMinID INT
SELECT @VacancyMinID = Vacancy_MaxID FROM SRV16.RabotaUA2.dbo.SpiderCompany_WorkStat WS WHERE WS.Date = DATEADD(DAY, -8, DATEADD(DAY, 1 - DATEPART(WEEKDAY, dbo.fnGetDatePart(GETDATE())),dbo.fnGetDatePart(GETDATE())));

SELECT @Work_NewVacancy = COUNT(DISTINCT SpiderVacancyID)
FROM Reporting.dbo.DimDate DD
	 JOIN SRV16.RabotaUA2.dbo.SpiderLoad_Sitemap V WITH (NOLOCK) ON DD.FullDate = V.VacancyDate
WHERE DD.FullDate BETWEEN DATEADD(DAY, -7, DATEADD(DAY, 1 - DATEPART(WEEKDAY, dbo.fnGetDatePart(GETDATE())),dbo.fnGetDatePart(GETDATE()))) AND DATEADD(DAY, -1, DATEADD(DAY, 1 - DATEPART(WEEKDAY, dbo.fnGetDatePart(GETDATE())),dbo.fnGetDatePart(GETDATE())))
 AND V.SpiderVacancyID BETWEEN @VacancyMinID AND @VacancyMaxID

UPDATE dbo.AggrManagementMetrics SET Work_NewVacancyCnt = @Work_NewVacancy WHERE YearNum = @YearNum AND WeekNum = @WeekNum;

---------------------------------------
-- Среднее кол-во вакансий на rabota.ua
---------------------------------------
DECLARE @Rabota_AvgVacancyCnt INT;

SELECT @Rabota_AvgVacancyCnt = AVG(VacancyCount)
FROM Reporting.dbo.DimDate DD
 JOIN SRV16.RabotaUA2.dbo.Spider2VacancyCountByCity VCBC WITH (NOLOCK) ON DD.FullDate = dbo.fnGetDatePart(VCBC.Date)
WHERE DD.YearNum = @YearNum AND DD.WeekNum = @WeekNum
 AND VCBC.CityID = 0
 AND VCBC.Source = 0

UPDATE dbo.AggrManagementMetrics SET Rabota_AvgVacancyCnt = @Rabota_AvgVacancyCnt WHERE YearNum = @YearNum AND WeekNum = @WeekNum;

---------------------------------------
-- Среднее кол-во вакансий на work.ua
---------------------------------------
DECLARE @Work_AvgVacancyCnt INT;

SELECT @Work_AvgVacancyCnt = AVG(VacancyCount)
FROM Reporting.dbo.DimDate DD
 JOIN SRV16.RabotaUA2.dbo.Spider2VacancyCountByCity VCBC WITH (NOLOCK) ON DD.FullDate = dbo.fnGetDatePart(VCBC.Date)
WHERE DD.YearNum = @YearNum AND DD.WeekNum = @WeekNum
 AND VCBC.CityID = 0
 AND VCBC.Source = 1

UPDATE dbo.AggrManagementMetrics SET Work_AvgVacancyCnt = @Work_AvgVacancyCnt WHERE YearNum = @YearNum AND WeekNum = @WeekNum;

---------------------------------------
-- Стоимость потребленного сервиса
---------------------------------------
DECLARE @RecognizedRevenue DECIMAL(18,2);

SELECT @RecognizedRevenue = SUM(RR.RecognizedRevenue)
FROM Reporting.dbo.FactRecognizedRevenue RR
 JOIN Reporting.dbo.DimDate DD ON RR.Date_key = DD.Date_key
WHERE YearNum = @YearNum
 AND WeekNum = @WeekNum;

UPDATE dbo.AggrManagementMetrics SET Rabota_SumRecognizedRevenue = @RecognizedRevenue WHERE YearNum = @YearNum AND WeekNum = @WeekNum;

---------------------------------------
-- Кол-во откликов на work.ua
---------------------------------------
DECLARE @ResponsesWork INT;

WITH C AS 
 (
SELECT *
 , DATEPART(YEAR, AddDate) AS YearNum
 , DATEPART(WEEK, AddDate) - 1 AS WeekNum
 , ROW_NUMBER() OVER(ORDER BY DATEPART(YEAR, AddDate), DATEPART(WEEK, AddDate) - 1) AS RowNum
FROM SRV16.RabotaUA2.dbo.SpiderLoad_WorkFormApply
WHERE DATEPART(WEEKDAY, AddDate) = 7
 )
SELECT @ResponsesWork = MAX(C1.Count) - MIN(C0.Count)
FROM C C1
 JOIN C C0 ON C1.RowNum = C0.RowNum + 1
WHERE C1.YearNum = @YearNum AND C1.WeekNum = @WeekNum - 1
GROUP BY C1.YearNum, C1.WeekNum;
 
UPDATE dbo.AggrManagementMetrics SET Work_ResponsesCnt = @ResponsesWork WHERE YearNum = @YearNum AND WeekNum = @WeekNum;

---------------------------------------
-- Кол-во откликов и пользователей с откликами
---------------------------------------
DECLARE @Responsers INT;
DECLARE @Responses INT;

SELECT 
   @Responsers = COUNT(DISTINCT EMail)
 , @Responses = COUNT(*)
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

UPDATE dbo.AggrManagementMetrics 
SET Rabota_ResponsesCnt = @Responses, Rabota_ResponsersNum = @Responsers
WHERE YearNum = @YearNum AND WeekNum = @WeekNum;

---------------------------------------
-- Кол-во откликов с десктопной версии сайта
---------------------------------------
DECLARE @Responses_Desktop INT;

SELECT 
   @Responses_Desktop = COUNT(*)
FROM 
 (
	SELECT
	   VATV.AddDate
	 , VA.EMail
	FROM SRV16.RabotaUA2.dbo.VacancyApplyToVacancy VATV WITH (NOLOCK)
	 JOIN SRV16.RabotaUA2.dbo.VacancyApplyCVs VACV WITH (NOLOCK) ON VATV.VacancyApplyCVsID = VACV.ID
	 JOIN SRV16.RabotaUA2.dbo.VacancyApply VA WITH (NOLOCK) ON VACV.VacancyApplyID = VA.ID
	WHERE VATV.AddDate BETWEEN @StartDate AND @EndDate + 1
	 AND VATV.IsFromMobile = 0

	UNION ALL
	-- отклики проф. резюме
	SELECT
	   RTV.AddDate
	 , RTV.Email
	FROM SRV16.RabotaUA2.dbo.ResumeToVacancy RTV WITH (NOLOCK)
	WHERE RTV.AddDate BETWEEN @StartDate AND @EndDate + 1
	 AND RTV.IsFromMobile = 0
 ) Resp 

UPDATE dbo.AggrManagementMetrics 
SET Rabota_ResponsesCnt_Desktop = @Responses_Desktop
WHERE YearNum = @YearNum AND WeekNum = @WeekNum;

---------------------------------------
-- Кол-во откликов с мобильной версии сайта
---------------------------------------
DECLARE @Responses_Mobile INT;

SELECT 
   @Responses_Mobile = COUNT(*)
FROM 
 (
	SELECT
	   VATV.AddDate
	 , VA.EMail
	FROM SRV16.RabotaUA2.dbo.VacancyApplyToVacancy VATV WITH (NOLOCK)
	 JOIN SRV16.RabotaUA2.dbo.VacancyApplyCVs VACV WITH (NOLOCK) ON VATV.VacancyApplyCVsID = VACV.ID
	 JOIN SRV16.RabotaUA2.dbo.VacancyApply VA WITH (NOLOCK) ON VACV.VacancyApplyID = VA.ID
	WHERE VATV.AddDate BETWEEN @StartDate AND @EndDate + 1
	 AND VATV.IsFromMobile = 1

	UNION ALL
	-- отклики проф. резюме
	SELECT
	   RTV.AddDate
	 , RTV.Email
	FROM SRV16.RabotaUA2.dbo.ResumeToVacancy RTV WITH (NOLOCK)
	WHERE RTV.AddDate BETWEEN @StartDate AND @EndDate + 1
	 AND RTV.IsFromMobile = 1
 ) Resp 

UPDATE dbo.AggrManagementMetrics 
SET Rabota_ResponsesCnt_Mobile = @Responses_Mobile
WHERE YearNum = @YearNum AND WeekNum = @WeekNum;

---------------------------------------
-- Кол-во просмотренных откликов
---------------------------------------
DECLARE @ResponsesViewed INT;

SELECT 
   @ResponsesViewed = COUNT(*)
FROM 
 (
	SELECT
	   VATV.ID
	FROM SRV16.RabotaUA2.dbo.VacancyApplyToVacancy VATV WITH (NOLOCK)
	WHERE VATV.AddDate BETWEEN @StartDate AND @EndDate + 1
	 AND VATV.ViewedDate IS NOT NULL

	UNION ALL
	-- отклики проф. резюме
	SELECT
	   RTV.ID
	FROM SRV16.RabotaUA2.dbo.ResumeToVacancy RTV WITH (NOLOCK)
	WHERE RTV.AddDate BETWEEN @StartDate AND @EndDate + 1
	 AND RTV.ViewedDate IS NOT NULL

	UNION ALL
	-- отклики аттачем повнорные (одного и того же соискателя на одну и ту же вакансию)
	SELECT
	   MEM.ID AS AddDate
	FROM SRV16.RabotaUA2.dbo.ResumeAttachToVacancy_Memory MEM WITH (NOLOCK)
	 JOIN SRV16.RabotaUA2.dbo.VacancyApplyToVacancy VATV WITH (NOLOCK) ON MEM.MemoryID = VATV.ID AND MEM.IsAttach = 1
	WHERE MEM.OldAddDate BETWEEN @StartDate AND @EndDate + 1
	 AND VATV.ViewedDate IS NOT NULL

	UNION ALL
	-- отклики проф.резюме повнорные (одного и того же соискателя на одну и ту же вакансию)
	SELECT
	   MEM.ID
	FROM SRV16.RabotaUA2.dbo.ResumeAttachToVacancy_Memory MEM WITH (NOLOCK)
	 JOIN SRV16.RabotaUA2.dbo.ResumeToVacancy RTV WITH (NOLOCK) ON MEM.MemoryID = RTV.ID AND MEM.ISAttach = 0
	WHERE MEM.OldAddDate BETWEEN @StartDate AND @EndDate + 1
	 AND RTV.ViewedDate IS NOT NULL
 ) Resp 

UPDATE dbo.AggrManagementMetrics 
SET Rabota_ResponsesCnt_Viewed = @ResponsesViewed
WHERE YearNum = @YearNum AND WeekNum = @WeekNum;

----------------------------------------------
-- Кол-во просмотренных откликов через попап
----------------------------------------------
DECLARE @ResponsesViewedPopup INT;

SELECT @ResponsesViewedPopup = COUNT(*)
FROM 
 (
	SELECT
	   VATV.ID
	FROM SRV16.RabotaUA2.dbo.VacancyApplyToVacancy VATV WITH (NOLOCK)
	WHERE VATV.AddDate BETWEEN @StartDate AND @EndDate + 1
	 AND VATV.IsRead_By15404 = 1 

	UNION ALL
	-- отклики проф. резюме
	SELECT
	   RTV.ID
	FROM SRV16.RabotaUA2.dbo.ResumeToVacancy RTV WITH (NOLOCK)
	WHERE RTV.AddDate BETWEEN @StartDate AND @EndDate + 1
	 AND RTV.IsRead_By15404 = 1

	UNION ALL
	-- отклики аттачем повнорные (одного и того же соискателя на одну и ту же вакансию)
	SELECT
	   MEM.ID AS AddDate
	FROM SRV16.RabotaUA2.dbo.ResumeAttachToVacancy_Memory MEM WITH (NOLOCK)
	 JOIN SRV16.RabotaUA2.dbo.VacancyApplyToVacancy VATV WITH (NOLOCK) ON MEM.MemoryID = VATV.ID AND MEM.IsAttach = 1
	WHERE MEM.OldAddDate BETWEEN @StartDate AND @EndDate + 1
	 AND VATV.IsRead_By15404 = 1

	UNION ALL
	-- отклики проф.резюме повнорные (одного и того же соискателя на одну и ту же вакансию)
	SELECT
	   MEM.ID
	FROM SRV16.RabotaUA2.dbo.ResumeAttachToVacancy_Memory MEM WITH (NOLOCK)
	 JOIN SRV16.RabotaUA2.dbo.ResumeToVacancy RTV WITH (NOLOCK) ON MEM.MemoryID = RTV.ID AND MEM.ISAttach = 0
	WHERE MEM.OldAddDate BETWEEN @StartDate AND @EndDate + 1
	 AND RTV.IsRead_By15404 = 1
 ) Resp 

UPDATE dbo.AggrManagementMetrics 
SET Rabota_ResponsesCnt_Viewed_Popup = @ResponsesViewedPopup
WHERE YearNum = @YearNum AND WeekNum = @WeekNum;

-----------------------------------------------------------------
-- Кол-во просмотренных откликов через (выбрать все и отметить)
-----------------------------------------------------------------
DECLARE @ResponsesViewedBulk INT;

SELECT @ResponsesViewedBulk = COUNT(*)
FROM 
 (
	SELECT
	   VATV.ID
	FROM SRV16.RabotaUA2.dbo.VacancyApplyToVacancy VATV WITH (NOLOCK)
	WHERE VATV.AddDate BETWEEN @StartDate AND @EndDate + 1
	 AND VATV.IsRead_By15620 = 1 

	UNION ALL
	-- отклики проф. резюме
	SELECT
	   RTV.ID
	FROM SRV16.RabotaUA2.dbo.ResumeToVacancy RTV WITH (NOLOCK)
	WHERE RTV.AddDate BETWEEN @StartDate AND @EndDate + 1
	 AND RTV.IsRead_By15620 = 1

	UNION ALL
	-- отклики аттачем повнорные (одного и того же соискателя на одну и ту же вакансию)
	SELECT
	   MEM.ID AS AddDate
	FROM SRV16.RabotaUA2.dbo.ResumeAttachToVacancy_Memory MEM WITH (NOLOCK)
	 JOIN SRV16.RabotaUA2.dbo.VacancyApplyToVacancy VATV WITH (NOLOCK) ON MEM.MemoryID = VATV.ID AND MEM.IsAttach = 1
	WHERE MEM.OldAddDate BETWEEN @StartDate AND @EndDate + 1
	 AND VATV.IsRead_By15620 = 1

	UNION ALL
	-- отклики проф.резюме повнорные (одного и того же соискателя на одну и ту же вакансию)
	SELECT
	   MEM.ID
	FROM SRV16.RabotaUA2.dbo.ResumeAttachToVacancy_Memory MEM WITH (NOLOCK)
	 JOIN SRV16.RabotaUA2.dbo.ResumeToVacancy RTV WITH (NOLOCK) ON MEM.MemoryID = RTV.ID AND MEM.ISAttach = 0
	WHERE MEM.OldAddDate BETWEEN @StartDate AND @EndDate + 1
	 AND RTV.IsRead_By15620 = 1
 ) Resp 

UPDATE dbo.AggrManagementMetrics 
SET Rabota_ResponsesCnt_Viewed_Bulk = @ResponsesViewedBulk
WHERE YearNum = @YearNum AND WeekNum = @WeekNum;

---------------------------------------
-- Кол-во новых пользователей
---------------------------------------
DECLARE @NewEmails INT;

SELECT @NewEmails = COUNT(*)
FROM SRV16.RabotaUA2.dbo.EMailSource ES WITH (NOLOCK)
WHERE ES.AddDate BETWEEN @StartDate AND @EndDate + 1

UPDATE dbo.AggrManagementMetrics 
SET Rabota_NewEmails = @NewEmails
WHERE YearNum = @YearNum AND WeekNum = @WeekNum;

---------------------------------------
-- % компаний в зеленой зоне
---------------------------------------
DECLARE @WeightTotal DECIMAL(4,1);
DECLARE @WeightSF DECIMAL(4,1);
DECLARE @WeightSMB DECIMAL(4,1);
DECLARE @WeightStarsTotal DECIMAL(4,1);
DECLARE @WeightStarsSF DECIMAL(4,1);
DECLARE @WeightStarsSMB DECIMAL(4,1);

SELECT @WeightTotal =
  100. * COUNT(*) 
   / (SELECT COUNT(*) FROM dbo.DimCompany WHERE VacancyDiffGroup <> 'R = W = 0' AND AgeGroup IN ('Подростки','Взрослые') AND WorkConnectionGroup = 'Привязанные компании' AND StarRating > 0)
FROM dbo.DimCompany DC
WHERE VacancyDiffGroup IN ('R > W = 0','R > W > 0','R = W')
 AND AgeGroup IN ('Подростки','Взрослые')
 AND WorkConnectionGroup = 'Привязанные компании'
 AND StarRating > 0;

SELECT @WeightSF =
  100. * COUNT(*) 
   / (SELECT COUNT(*) FROM dbo.DimCompany WHERE VacancyDiffGroup <> 'R = W = 0' AND DepartmentName IN ('Sales Force') AND AgeGroup IN ('Подростки','Взрослые') AND WorkConnectionGroup = 'Привязанные компании' AND StarRating > 0)
FROM dbo.DimCompany DC
WHERE VacancyDiffGroup IN ('R > W = 0','R > W > 0','R = W')
 AND AgeGroup IN ('Подростки','Взрослые')
 AND WorkConnectionGroup = 'Привязанные компании'
 AND StarRating > 0
 AND DepartmentName IN ('Sales Force');

SELECT @WeightSMB =
  100. * COUNT(*) 
   / (SELECT COUNT(*) FROM dbo.DimCompany WHERE VacancyDiffGroup <> 'R = W = 0' AND DepartmentName IN ('Telesales','Teleinfo') AND AgeGroup IN ('Подростки','Взрослые') AND WorkConnectionGroup = 'Привязанные компании' AND StarRating > 0)
FROM dbo.DimCompany DC
WHERE VacancyDiffGroup IN ('R > W = 0','R > W > 0','R = W')
 AND AgeGroup IN ('Подростки','Взрослые')
 AND WorkConnectionGroup = 'Привязанные компании'
 AND StarRating > 0
 AND DepartmentName IN ('Telesales','Teleinfo');

SELECT @WeightStarsTotal =
  100. * COUNT(*) 
   / (SELECT COUNT(*) FROM dbo.DimCompany WHERE VacancyDiffGroup <> 'R = W = 0' AND AgeGroup IN ('Подростки','Взрослые') AND WorkConnectionGroup = 'Привязанные компании' AND StarRating >= 4)
FROM dbo.DimCompany DC
WHERE VacancyDiffGroup IN ('R > W = 0','R > W > 0','R = W')
 AND AgeGroup IN ('Подростки','Взрослые')
 AND WorkConnectionGroup = 'Привязанные компании'
 AND StarRating >= 4;

SELECT @WeightStarsSF =
  100. * COUNT(*) 
   / (SELECT COUNT(*) FROM dbo.DimCompany WHERE VacancyDiffGroup <> 'R = W = 0' AND DepartmentName IN ('Sales Force') AND AgeGroup IN ('Подростки','Взрослые') AND WorkConnectionGroup = 'Привязанные компании' AND StarRating >= 4)
FROM dbo.DimCompany DC
WHERE VacancyDiffGroup IN ('R > W = 0','R > W > 0','R = W')
 AND AgeGroup IN ('Подростки','Взрослые')
 AND WorkConnectionGroup = 'Привязанные компании'
 AND StarRating >= 4
 AND DepartmentName IN ('Sales Force');

SELECT @WeightStarsSMB =
  100. * COUNT(*) 
   / (SELECT COUNT(*) FROM dbo.DimCompany WHERE VacancyDiffGroup <> 'R = W = 0' AND DepartmentName IN ('Telesales','Teleinfo') AND AgeGroup IN ('Подростки','Взрослые') AND WorkConnectionGroup = 'Привязанные компании' AND StarRating >= 4)
FROM dbo.DimCompany DC
WHERE VacancyDiffGroup IN ('R > W = 0','R > W > 0','R = W')
 AND AgeGroup IN ('Подростки','Взрослые')
 AND WorkConnectionGroup = 'Привязанные компании'
 AND StarRating >= 4
 AND DepartmentName IN ('Telesales','Teleinfo');

UPDATE dbo.AggrManagementMetrics 
SET 
	Rabota_GreenWeightTotal = @WeightTotal,
	Rabota_GreenWeightSF = @WeightSF,
	Rabota_GreenWeightSMB = @WeightSMB,
	Rabota_StarsGreenWeightTotal = @WeightStarsTotal,
	Rabota_StarsGreenWeightSF = @WeightStarsSF,
	Rabota_StarsGreenWeightSMB = @WeightStarsSMB
WHERE YearNum = @YearNum AND WeekNum = @WeekNum;

--------------------------------------------------
-- Удельный вес платных публикаций на rabota.ua --
--------------------------------------------------
DECLARE @PaidWeight DECIMAL(18,15);

WITH C AS
 (
SELECT 
   CASE 
    WHEN ISNULL(TP.SummStandart,0) + ISNULL(SummDesigned,0) + ISNULL(SummVip,0) + ISNULL(SummHot,0) > 0 THEN 1
    WHEN ISNULL(RTP.TicketSumm, 0) > 0 THEN 1
    ELSE 0 
   END AS IsPaidPublication
 , SpendCount
FROM Analytics.dbo.NotebookCompany_Spent NCS
 JOIN Reporting.dbo.DimDate DD ON CONVERT(DATE, NCS.AddDate) = DD.FullDate
 LEFT JOIN Analytics.dbo.TicketPayment TP ON NCS.TicketPaymentID = TP.Id AND NCS.RegionalPackageID IS NULL
 LEFT JOIN Analytics.dbo.RegionalTicketPayment RTP ON NCS.TicketPaymentID = RTP.Id AND NCS.RegionalPackageID IS NOT NULL
WHERE DD.FullDate BETWEEN @StartDate AND @EndDate
 )
 , C2 AS
 (
SELECT IsPaidPublication, SUM(SpendCount) AS SumSpendCount, SUM(SUM(SpendCount)) OVER() AS PubTotal
 , 1. * SUM(SpendCount) / SUM(SUM(SpendCount)) OVER() AS PayTypeWeight
FROM C
GROUP BY IsPaidPublication
 )
SELECT @PaidWeight = PayTypeWeight 
FROM C2
WHERE IsPaidPublication = 1;

UPDATE dbo.AggrManagementMetrics
SET Rabota_PaidPublicationsWeight = @PaidWeight
WHERE YearNum = @YearNum AND WeekNum = @WeekNum;

-----------------------------------------------------------------------
-- Среднее кол-во откликов в неделю в зависимости от типа публикации --
-----------------------------------------------------------------------
-- список вакансий которые публиковались в течении отчетной недели
IF OBJECT_ID('tempdb..#T','U') IS NOT NULL DROP TABLE #T;

SELECT 
   VSH.VacancyId
 , CASE WHEN VC.CityId = 1 THEN 1 ELSE 0 END AS IsKiev
 , CASE WHEN [DateTime] <= @StartDate THEN @StartDate ELSE [DateTime] END AS DateTime_Start
 , CASE WHEN VSH.[DateTime] = DateTimeUpd THEN @EndDate ELSE DateTimeUpd END AS DateTime_End
 , (SELECT COUNT(*) FROM dbo.DimDate 
	WHERE FullDate BETWEEN 
		CONVERT(DATE, CASE WHEN [DateTime] <= @StartDate THEN @StartDate ELSE [DateTime] END) 
		 AND CONVERT(DATE, CASE WHEN VSH.[DateTime] = DateTimeUpd THEN @EndDate ELSE DateTimeUpd END)) AS DaysCount
INTO #T
FROM SRV16.RabotaUA2.dbo.VacancyStateHistory VSH WITH (NOLOCK)
 JOIN SRV16.RabotaUA2.dbo.VacancyCity VC WITH (NOLOCK) ON VSH.VacancyID = VC.VacancyID
WHERE VSH.[State] = 4
 AND ((VSH.[DateTime] = DateTimeUpd AND DateTime <= @EndDate + 1) OR (DateTimeUpd BETWEEN @StartDate AND @EndDate + 1)) 
 ;

-- список потраченных горячих публикаций с датами начала и конца "горячести"
IF OBJECT_ID('tempdb..#HotVacancyDates','U') IS NOT NULL DROP TABLE #HotVacancyDates;

SELECT 
   VacancyID
 , CONVERT(DATE, AddDate) AS HotStartDate
 , DATEADD(DAY, SpendCount * 7, CONVERT(DATE, AddDate)) AS HotEndDate
INTO #HotVacancyDates
FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent NCS WITH (NOLOCK)
WHERE SpendType = 5;

-- список вакансий, которые были горячими не менее 4-х дней, с кол-вом откликов за период публикации в рамках недели
IF OBJECT_ID('tempdb..#Hots','U') IS NOT NULL DROP TABLE #Hots;

SELECT 
   T.VacancyId
 , T.IsKiev
 , T.DateTime_Start
 , T.DateTime_End
 , T.DaysCount
 , HVD.HotStartDate
 , HVD.HotEndDate
 , DaysCount * dbo.fnGetPeriodIntersection(dbo.fnDayByDate(DateTime_Start), dbo.fnDayByDate(DateTime_End), dbo.fnDayByDate(HotStartDate), dbo.fnDayByDate(HotEndDate)) AS DaysInHot
 , (SELECT COUNT(*) FROM SRV16.RabotaUA2.dbo.VacancyApplyToVacancy WITH (NOLOCK) WHERE VacancyId = T.VacancyId AND AddDate BETWEEN T.DateTime_Start AND T.DateTime_End)
    + (SELECT COUNT(*) FROM SRV16.RabotaUA2.dbo.ResumeToVacancy WITH (NOLOCK) WHERE VacancyId = T.VacancyId AND AddDate BETWEEN T.DateTime_Start AND T.DateTime_End) AS RespCount
INTO #Hots
FROM #T T
 JOIN #HotVacancyDates HVD ON T.VacancyId = HVD.VacancyID
WHERE DaysCount >= 4
 AND (DateTime_Start BETWEEN HotStartDate AND HotEndDate OR DateTime_End BETWEEN HotStartDate AND HotEndDate)
 AND DaysCount * dbo.fnGetPeriodIntersection(dbo.fnDayByDate(DateTime_Start), dbo.fnDayByDate(DateTime_End), dbo.fnDayByDate(HotStartDate), dbo.fnDayByDate(HotEndDate)) >= 4
ORDER BY DaysCount;

-- Вакансии, которые не были горячими и были проф. или оптимум.
IF OBJECT_ID('tempdb..#NotHot','U') IS NOT NULL DROP TABLE #NotHot;

WITH C AS
 (
SELECT NCS.*, ROW_NUMBER() OVER(PARTITION BY NCS.VacancyID ORDER BY AddDate DESC) AS RowNum
FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent NCS WITH (NOLOCK)
 JOIN #T T ON NCS.VacancyID = T.VacancyID
WHERE NCS.AddDate <= T.DateTime_Start
 AND NCS.AddDate >= DATEADD(MONTH, -1, @StartDate)
 )

SELECT T.*
 , CASE 
    WHEN SpendType = 4 THEN 'Basic' ELSE 'Optimum + Prof'
   END AS PubType
 , (SELECT COUNT(*) FROM SRV16.RabotaUA2.dbo.VacancyApplyToVacancy WITH (NOLOCK) WHERE VacancyId = T.VacancyId AND AddDate BETWEEN T.DateTime_Start AND T.DateTime_End)
    + (SELECT COUNT(*) FROM SRV16.RabotaUA2.dbo.ResumeToVacancy WITH (NOLOCK) WHERE VacancyId = T.VacancyId AND AddDate BETWEEN T.DateTime_Start AND T.DateTime_End) AS RespCount
INTO #NotHot
FROM #T T
 JOIN C ON T.VacancyID = C.VacancyID AND RowNum = 1
WHERE NOT EXISTS (SELECT * FROM #Hots WHERE VacancyId = T.VacancyID)
 AND DaysCount >= 4;

-- среднее кол-во откликов в разбивке Киев / Не-Киев по типам публикаций
IF OBJECT_ID('tempdb..#Result','U') IS NOT NULL DROP TABLE #Result;

SELECT PubType, IsKiev, AVG(1. * RespCount) AS AvgResp
INTO #Result
FROM #NotHot
GROUP BY PubType, IsKiev

UNION ALL

SELECT 'Hot' AS PubType, IsKiev, AVG(1. * RespCount) 
FROM #Hots
GROUP BY IsKiev;

UPDATE dbo.AggrManagementMetrics SET AvgResponsesHot_Kiev = (SELECT AvgResp FROM #Result WHERE IsKiev = 1 AND PubType = 'Hot') WHERE YearNum = @YearNum AND WeekNum = @WeekNum; 
UPDATE dbo.AggrManagementMetrics SET AvgResponsesHot_NotKiev = (SELECT AvgResp FROM #Result WHERE IsKiev = 0 AND PubType = 'Hot') WHERE YearNum = @YearNum AND WeekNum = @WeekNum; 
UPDATE dbo.AggrManagementMetrics SET AvgResponsesBasic_Kiev = (SELECT AvgResp FROM #Result WHERE IsKiev = 1 AND PubType = 'Basic') WHERE YearNum = @YearNum AND WeekNum = @WeekNum; 
UPDATE dbo.AggrManagementMetrics SET AvgResponsesBasic_NotKiev = (SELECT AvgResp FROM #Result WHERE IsKiev = 0 AND PubType = 'Basic') WHERE YearNum = @YearNum AND WeekNum = @WeekNum; 
UPDATE dbo.AggrManagementMetrics SET AvgResponsesOptiprof_Kiev = (SELECT AvgResp FROM #Result WHERE IsKiev = 1 AND PubType = 'Optimum + Prof') WHERE YearNum = @YearNum AND WeekNum = @WeekNum; 
UPDATE dbo.AggrManagementMetrics SET AvgResponsesOptiprof_NotKiev = (SELECT AvgResp FROM #Result WHERE IsKiev = 0 AND PubType = 'Optimum + Prof') WHERE YearNum = @YearNum AND WeekNum = @WeekNum; 

DROP TABLE #T;
DROP TABLE #HotVacancyDates;
DROP TABLE #Hots;
DROP TABLE #NotHot;
DROP TABLE #Result;