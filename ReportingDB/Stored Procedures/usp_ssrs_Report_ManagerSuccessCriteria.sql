
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-05-19
-- Description:	Процедура возвращает плановые и фактические показатели по каждому менеджеру,
--				определенному параметром @ManagerIDs за квартал или месяц (в зависимости от значения
--				параметра @TimePeriodType (1 - месяц, 2 - квартал)). "Номер" кваратала или месяца 
--				задается параметром @TimePeriodNum
-- ======================================================================================================

CREATE PROCEDURE [dbo].[usp_ssrs_Report_ManagerSuccessCriteria] 
	(@ManagerIDs NVARCHAR(1000), @YearNum SMALLINT, @TimePeriodType TINYINT, @TimePeriodNum TINYINT)

AS

BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @Today DATE = CONVERT(DATE, GETDATE());

	-- Начальная и конечная даты отчетного периода
	DECLARE @StartDate DATETIME
		=  (SELECT DISTINCT CASE WHEN @TimePeriodType = 1 THEN FirstMonthDate WHEN @TimePeriodType = 2 THEN FirstQuarterDate END
			FROM dbo.DimDate
			WHERE YearNum = @YearNum AND CASE WHEN @TimePeriodType = 1 THEN MonthNum WHEN @TimePeriodType = 2 THEN QuarterNum END = @TimePeriodNum);

	DECLARE @EndDate DATETIME
		=  (SELECT DISTINCT CASE WHEN @TimePeriodType = 1 THEN LastMonthDate WHEN @TimePeriodType = 2 THEN LastQuarterDate END
			FROM dbo.DimDate
			WHERE YearNum = @YearNum AND CASE WHEN @TimePeriodType = 1 THEN MonthNum WHEN @TimePeriodType = 2 THEN QuarterNum END = @TimePeriodNum);

	-- Отчетная дата (для случаев, если пользователь выбрал незавершенный период, и показатель считается по состоянию на дату)
	DECLARE @ReportDate DATE = dbo.fnGetMinimumOf2ValuesDate (@Today, DATEADD(DAY, 1, @EndDate));

	-- номер квартала
	DECLARE @QuarterNum TINYINT;
	
	IF @TimePeriodType = 2 
		SET @QuarterNum  = @TimePeriodNum
	ELSE 
		SET @QuarterNum = (SELECT DISTINCT QuarterNum FROM dbo.DimDate WHERE YearNum = @YearNum AND MonthNum = @TimePeriodNum);


	-- временная таблица со списком менеджеров, у которых в течении отчетного периода, был хотя бы 1 полный месяц рабочего стажа
	IF OBJECT_ID('tempdb..#ManagerList','U') IS NOT NULL DROP TABLE #ManagerList;

	SELECT 
	   M.Id AS ManagerID
	 , M.Name AS ManagerName
	 , CASE WHEN M.STM_ManagerID = M.TeamLead_ManagerID THEN M.Id ELSE M.STM_ManagerID END AS STM_ManagerID
	 , CASE WHEN M.STM_ManagerID = M.TeamLead_ManagerID THEN M.Name ELSE STM.Name END AS STM_Name
	 , COALESCE(M.TeamLead_ManagerID, M.Id) AS TeamLead_ManagerID
	 , COALESCE(TL.Name, M.Name) AS TeamLead_Name
	 , MMB.Email AS ManagerEmail
	 , M.AddDate AS ManagerAddDate
	 , dbo.udf_FullMonthsSeparation(FD.FullDate, @StartDate) AS WorkExperience_StartDate
	 , dbo.udf_FullMonthsSeparation(FD.FullDate, @EndDate) AS WorkExperience_EndDate
	INTO #ManagerList
	FROM SRV16.RabotaUA2.dbo.Manager M
	 JOIN SRV16.RabotaUA2.dbo.aspnet_Membership MMB ON M.aspnet_UserUIN = MMB.UserId
	 LEFT JOIN SRV16.RabotaUA2.dbo.Manager STM ON M.STM_ManagerID = STM.Id
	 LEFT JOIN SRV16.RabotaUA2.dbo.Manager TL ON M.TeamLead_ManagerID = TL.Id
	 JOIN (SELECT FullDate
			FROM DimDate
			WHERE DayNum = 1) FD ON FullDate BETWEEN M.AddDate AND DATEADD(MONTH, 1, M.AddDate) 
	WHERE M.Id IN (SELECT Value FROM dbo.udf_SplitString(@ManagerIDs, ','))
	 AND dbo.udf_FullMonthsSeparation(FD.FullDate, @StartDate) >= CASE WHEN @TimePeriodType = 1 THEN 0 WHEN @TimePeriodType = 2 THEN -2 END;  -- стаж на момент начала отчетного периода как минимум 1 месяц

	-- временная таблица с плановыми показателями менеджера в отчетном периоде
	IF OBJECT_ID('tempdb..#ManagerPlanList','U') IS NOT NULL DROP TABLE #ManagerPlanList;

	WITH C AS
	 (
	SELECT 
	   ML.ManagerID
	 , ML.ManagerName
	 , ML.STM_ManagerID
	 , ML.STM_Name
	 , ML.TeamLead_ManagerID
	 , ML.TeamLead_Name
	 , ML.ManagerEmail
	 , ML.ManagerAddDate
	 , ML.WorkExperience_StartDate
	 , ML.WorkExperience_EndDate
	 , (SELECT FirstMonthDate FROM dbo.DimDate WHERE FullDate = CONVERT(DATE, DATEADD(MONTH, TRG.WorkExperienceFullMonths, ManagerAddDate))) AS FirstMonthDate
	 , (SELECT LastMonthDate FROM dbo.DimDate WHERE FullDate = CONVERT(DATE, DATEADD(MONTH, TRG.WorkExperienceFullMonths, ManagerAddDate))) AS LastMonthDate
	 , TRG.ContactsPerDay
	 , TRG.MeetingsNumMonth
	 , TRG.PaidCompaniesNum
	 , TRG.FinancePlanMonth
	 , TRG.RecognizedRevenueMonth
	 , TRG.UnqVacancyWeightMonth
	FROM #ManagerList ML
	 LEFT JOIN dbo.TargetsMonthByWorkExperience TRG 
	  ON TRG.WorkExperienceFullMonths - 1 BETWEEN ML.WorkExperience_StartDate AND ML.WorkExperience_EndDate
	 )
   , C2 AS
     ( 
	SELECT
  	   ManagerID
	 , ManagerName
	 , STM_ManagerID
	 , STM_Name
	 , TeamLead_ManagerID
	 , TeamLead_Name
	 , ManagerEmail
	 , ManagerAddDate
	 , WorkExperience_StartDate
	 , WorkExperience_EndDate
	 , FirstMonthDate
	 , LastMonthDate
	 , (SELECT COUNT(*) 
		FROM dbo.DimDate 
		WHERE FullDate BETWEEN C.FirstMonthDate AND CASE WHEN @Today < C.LastMonthDate THEN @Today ELSE C.LastMonthDate END
		 AND WeekDayNum NOT IN (6,7) 
		 AND ISNULL(IsHoliday, 0) = 0) AS WorkingDays
	 , (SELECT COUNT(*) 
		FROM dbo.DimDate 
		WHERE FullDate BETWEEN C.FirstMonthDate AND C.LastMonthDate
		 AND WeekDayNum NOT IN (6,7) 
		 AND ISNULL(IsHoliday, 0) = 0) AS WorkingDaysTotalMonth
	 , ContactsPerDay
	 , MeetingsNumMonth
	 , PaidCompaniesNum
	 , FinancePlanMonth
	 , RecognizedRevenueMonth
	 , UnqVacancyWeightMonth
	FROM C
	 )
	SELECT 
	   ManagerID
	 , ManagerName
	 , STM_ManagerID
	 , STM_Name
	 , TeamLead_ManagerID
	 , TeamLead_Name
	 , ManagerEmail
	 , ManagerAddDate
	 , WorkExperience_StartDate
	 , WorkExperience_EndDate
	 , SUM(WorkingDays * ContactsPerDay) AS Plan_ActionsCount
	 , SUM(CONVERT(INT, 1. * MeetingsNumMonth * WorkingDays / WorkingDaysTotalMonth)) AS Plan_MeetingsCount
	 , MAX(PaidCompaniesNum) AS Plan_PaidCompaniesNum
	 , SUM(CONVERT(DECIMAL(16,2), 1. * FinancePlanMonth * WorkingDays / WorkingDaysTotalMonth)) AS Plan_Finance
	 , SUM(CONVERT(DECIMAL(16,2), 1. * RecognizedRevenueMonth * WorkingDays / WorkingDaysTotalMonth)) AS Plan_Revenue
	 , AVG(UnqVacancyWeightMonth) AS Plan_UnqWeight
	INTO #ManagerPlanList
	FROM C2
	GROUP BY 
	   ManagerID
	 , ManagerName
	 , STM_ManagerID
	 , STM_Name
	 , TeamLead_ManagerID
	 , TeamLead_Name
	 , ManagerEmail
	 , ManagerAddDate
	 , WorkExperience_StartDate
	 , WorkExperience_EndDate;

	-- временная таблица со средними весами уникальных вакансий по выбранным менеджерам 
	IF OBJECT_ID('tempdb..#UnqWeight','U') IS NOT NULL DROP TABLE #UnqWeight;

	SELECT ManagerEmail, AVG(UnqWeight) AS AvgUnqWeight
	INTO #UnqWeight
	FROM 
		(
		SELECT C.ManagerEmail, CS.Date_key, 1. * SUM(CS.VacancyNum) / NULLIF((SUM(CS.VacancyNum) + SUM(CS.UnqWorkVacancyNum)),0) AS UnqWeight
		FROM dbo.FactCompanyStatuses CS
			JOIN dbo.DimCompany C ON CS.Company_key = C.Company_key
			JOIN dbo.DimDate D ON CS.Date_key = D.Date_key
		WHERE D.FullDate BETWEEN @StartDate AND DATEADD(DAY, 1, @EndDate)
		 AND EXISTS (SELECT * FROM #ManagerList WHERE ManagerEmail = C.ManagerEmail)
		 AND C.WorkConnectionGroup = 'Привязанные компании'
		GROUP BY C.ManagerEmail, CS.Date_key
		) UnqByDays
	GROUP BY ManagerEmail;

	-- итоговая таблица с плановыми и фактическими показателями
	WITH C AS
	 (
	SELECT MPL.*
	 , (SELECT COUNT(*) 
		FROM SRV16.RabotaUA2.dbo.CRM_Action A
		WHERE A.Responsible = MPL.ManagerEmail
		 AND StateID = 2
		 AND TypeID IN (1,2,3,4,5,7,8)
		 AND A.CompleteDate BETWEEN @StartDate AND DATEADD(DAY, 1, @EndDate)) AS Fact_ActionsCount
	 , (SELECT COUNT(*) 
		FROM SRV16.RabotaUA2.dbo.CRM_Action A
	    WHERE A.Responsible = MPL.ManagerEmail
		 AND StateID = 2
		 AND TypeID IN (8)
		 AND A.CompleteDate BETWEEN @StartDate AND DATEADD(DAY, 1, @EndDate)) AS Fact_MeetingsCount
	 , (SELECT COUNT(*) 
		FROM dbo.FactCompanyStatuses CS
		 JOIN dbo.DimCompany C ON CS.Company_key = C.Company_key
		 JOIN dbo.DimDate D ON CS.Date_key = D.Date_key
		WHERE D.FullDate = @ReportDate
		 AND C.ManagerEmail = MPL.ManagerEmail
		 AND CS.HasPaidServices = 1) AS Fact_PaidCompanies
	 , ISNULL(
		   (SELECT SUM(PaySum) 
			FROM SRV16.RabotaUA2.dbo.Order_AccPayment OAP
			 JOIN SRV16.RabotaUA2.dbo.Order_Acc OA ON OAP.AccID = OA.ID AND OAP.AccYear = OA.[Year]
			WHERE OAP.PayDate BETWEEN @StartDate AND DATEADD(DAY, 1, @EndDate)
			 AND OA.LoginEMail_PaidOwner = MPL.ManagerEmail) 
	   , 0) AS Fact_Finance
	 , ISNULL(
		   (SELECT SUM(RecognizedRevenue)
			FROM dbo.FactRecognizedRevenueNotebook RRN
			 JOIN dbo.DimDate DD ON RRN.Date_key = DD.Date_key
			 JOIN dbo.DimCompany DC ON RRN.NotebookID = DC.NotebookId
			WHERE DD.FullDate BETWEEN @StartDate AND @EndDate
			 AND DC.ManagerEmail = MPL.ManagerEmail)
	   , 0) AS Fact_Revenue
	 , UW.AvgUnqWeight AS Fact_UnqWeight
	FROM #ManagerPlanList MPL
	 JOIN #UnqWeight UW ON MPL.ManagerEmail = UW.ManagerEmail
	)
	
	SELECT *
	 , CASE 
			WHEN Plan_ActionsCount <= Fact_ActionsCount 
				AND Plan_MeetingsCount <= Fact_MeetingsCount
				AND Plan_PaidCompaniesNum <= Fact_PaidCompanies 
				AND Plan_Finance <= Fact_Finance
				AND Plan_Revenue <= Fact_Revenue
				AND Plan_UnqWeight <= Fact_UnqWeight
			THEN 'OK'
			ELSE 'NOT OK'
		END AS IsSuccess
	 , @QuarterNum AS QuarterNum
	FROM C;
	
END;