
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-05-19
-- Description:	Процедура возвращает плановые и фактические показатели по выбранному менеджеру,
--				определенному параметром @ManagerID за квартал, определенный параметрами @QuarterNum,
--				года, определенного параметром @YearNum
-- ======================================================================================================

CREATE PROCEDURE dbo.usp_ssrs_Report_ManagerSuccessCriteriaSubreport
	(@ManagerID SMALLINT, @YearNum SMALLINT, @QuarterNum TINYINT)

AS

BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @Today DATE = CONVERT(DATE, GETDATE());

	-- Начальная и конечная даты отчетного периода
	DECLARE @StartDate DATETIME	= (SELECT DISTINCT FirstQuarterDate	FROM dbo.DimDate WHERE YearNum = @YearNum AND QuarterNum = @QuarterNum);
	DECLARE @EndDate DATETIME = (SELECT DISTINCT LastQuarterDate FROM dbo.DimDate WHERE YearNum = @YearNum AND QuarterNum = @QuarterNum);

	-- Отчетная дата (для случаев, если пользователь выбрал незавершенный период, и показатель считается по состоянию на дату)
	DECLARE @ReportDate DATE = dbo.fnGetMinimumOf2ValuesDate (@Today, DATEADD(DAY, 1, @EndDate));

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
	WHERE M.Id IN (@ManagerID)
		AND dbo.udf_FullMonthsSeparation(FD.FullDate, @StartDate) >= -2;  -- стаж на момент начала отчетного периода как минимум 1 месяц

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
		, C2.FirstMonthDate
		, C2.LastMonthDate
		, D.YearNum
		, D.MonthNum
		, D.MonthNameRus
		, WorkingDays * ContactsPerDay AS Plan_ActionsCount
		, CONVERT(INT, 1. * MeetingsNumMonth * WorkingDays / WorkingDaysTotalMonth) AS Plan_MeetingsCount
		, PaidCompaniesNum AS Plan_PaidCompaniesNum
		, CONVERT(DECIMAL(16,2), 1. * FinancePlanMonth * WorkingDays / WorkingDaysTotalMonth) AS Plan_Finance
		, CONVERT(DECIMAL(16,2), 1. * RecognizedRevenueMonth * WorkingDays / WorkingDaysTotalMonth) AS Plan_Revenue
		, UnqVacancyWeightMonth AS Plan_UnqWeight
	INTO #ManagerPlanList 
	FROM C2
	 JOIN dbo.DimDate D ON C2.LastMonthDate = D.FullDate

	-- временная таблица со средними весами уникальных вакансий по выбранным менеджерам 
	IF OBJECT_ID('tempdb..#UnqWeight','U') IS NOT NULL DROP TABLE #UnqWeight;

	SELECT ManagerEmail, YearNum, MonthNum, AVG(UnqWeight) AS AvgUnqWeight
	INTO #UnqWeight
	FROM 
		(
		SELECT C.ManagerEmail, CS.Date_key, D.YearNum, D.MonthNum, 1. * SUM(CS.VacancyNum) / NULLIF((SUM(CS.VacancyNum) + SUM(CS.UnqWorkVacancyNum)),0) AS UnqWeight
		FROM dbo.FactCompanyStatuses CS
			JOIN dbo.DimCompany C ON CS.Company_key = C.Company_key
			JOIN dbo.DimDate D ON CS.Date_key = D.Date_key
		WHERE D.FullDate BETWEEN @StartDate AND DATEADD(DAY, 1, @EndDate)
			AND EXISTS (SELECT * FROM #ManagerList WHERE ManagerEmail = C.ManagerEmail)
			AND C.WorkConnectionGroup = 'Привязанные компании'
		GROUP BY C.ManagerEmail, CS.Date_key, D.YearNum, D.MonthNum
		) UnqByDays
	GROUP BY ManagerEmail, YearNum, MonthNum;

	-- временная таблица с кол-вом контактов по выбранным менеджерам
	IF OBJECT_ID('tempdb..#Contacts','U') IS NOT NULL DROP TABLE #Contacts;

	SELECT A.Responsible AS ManagerEmail, DATEPART(YEAR, A.CompleteDate) AS YearNum, DATEPART(MONTH, A.CompleteDate) AS MonthNum, COUNT(*) AS ActionsCount
	INTO #Contacts
	FROM SRV16.RabotaUA2.dbo.CRM_Action A
	WHERE StateID = 2
	 AND TypeID IN (1,2,3,4,5,7,8)
	 AND A.CompleteDate BETWEEN @StartDate AND DATEADD(DAY, 1, @EndDate)
	 AND EXISTS (SELECT * FROM #ManagerList WHERE ManagerEmail = A.Responsible)
	GROUP BY A.Responsible, DATEPART(YEAR, A.CompleteDate), DATEPART(MONTH, A.CompleteDate);

	-- временная таблица с кол-вом встреч по выбранным менеджерам
	IF OBJECT_ID('tempdb..#Meetings','U') IS NOT NULL DROP TABLE #Meetings;

	SELECT A.Responsible AS ManagerEmail, DATEPART(YEAR, A.CompleteDate) AS YearNum, DATEPART(MONTH, A.CompleteDate) AS MonthNum, COUNT(*) AS MeetingsCount
	INTO #Meetings
	FROM SRV16.RabotaUA2.dbo.CRM_Action A
	WHERE StateID = 2
	 AND TypeID IN (8)
	 AND A.CompleteDate BETWEEN @StartDate AND DATEADD(DAY, 1, @EndDate)
	 AND EXISTS (SELECT * FROM #ManagerList WHERE ManagerEmail = A.Responsible)
	GROUP BY A.Responsible, DATEPART(YEAR, A.CompleteDate), DATEPART(MONTH, A.CompleteDate);
	
	-- временная таблица с расчитанными показателями
	IF OBJECT_ID('tempdb..#T','U') IS NOT NULL DROP TABLE #T;
	
	WITH C AS
		(
	SELECT MPL.*
		, ISNULL(C.ActionsCount, 0) AS Fact_ActionsCount
		, ISNULL(M.MeetingsCount,0) AS Fact_MeetingsCount
		, (SELECT COUNT(*) 
		FROM dbo.FactCompanyStatuses CS
			JOIN dbo.DimCompany C ON CS.Company_key = C.Company_key
			JOIN dbo.DimDate D ON CS.Date_key = D.Date_key
		WHERE D.FullDate = CASE WHEN @Today < MPL.LastMonthDate THEN @Today ELSE DATEADD(DAY, 1, MPL.LastMonthDate) END
			AND C.ManagerEmail = MPL.ManagerEmail
			AND CS.HasPaidServices = 1) AS Fact_PaidCompanies
		, ISNULL(
			(SELECT SUM(PaySum) 
			FROM SRV16.RabotaUA2.dbo.Order_AccPayment OAP
				JOIN SRV16.RabotaUA2.dbo.Order_Acc OA ON OAP.AccID = OA.ID AND OAP.AccYear = OA.[Year]
			WHERE OAP.PayDate BETWEEN MPL.FirstMonthDate AND DATEADD(DAY, 1, MPL.LastMonthDate)
				AND OA.LoginEMail_PaidOwner = MPL.ManagerEmail) 
		, 0) AS Fact_Finance
		, ISNULL(
			(SELECT SUM(RecognizedRevenue)
			FROM dbo.FactRecognizedRevenueNotebook RRN
				JOIN dbo.DimDate DD ON RRN.Date_key = DD.Date_key
				JOIN dbo.DimCompany DC ON RRN.NotebookID = DC.NotebookId
			WHERE DD.FullDate BETWEEN MPL.FirstMonthDate AND MPL.LastMonthDate
				AND DC.ManagerEmail = MPL.ManagerEmail)
		, 0) AS Fact_Revenue
		, UW.AvgUnqWeight AS Fact_UnqWeight
	FROM #ManagerPlanList MPL
		JOIN #UnqWeight UW ON MPL.ManagerEmail = UW.ManagerEmail AND MPL.YearNum = UW.YearNum AND MPL.MonthNum = UW.MonthNum
		LEFT JOIN #Contacts C ON MPL.ManagerEmail = C.ManagerEmail AND MPL.YearNum = C.YearNum AND MPL.MonthNum = C.MonthNum 
		LEFT JOIN #Meetings M ON MPL.ManagerEmail = M.ManagerEmail AND MPL.YearNum = M.YearNum AND MPL.MonthNum = M.MonthNum  
		)

	SELECT 
	      ManagerID
		, ManagerName
		, ManagerEmail
		, Plan_ActionsCount
		, Plan_MeetingsCount
		, Plan_PaidCompaniesNum
		, Plan_Finance
		, Plan_Revenue
		, Plan_UnqWeight
		, Fact_ActionsCount
		, Fact_MeetingsCount
		, Fact_PaidCompanies
		, Fact_Finance
		, Fact_Revenue
		, Fact_UnqWeight
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
	   , MonthNum AS MonthInQuarterNum
	   , MonthNameRus
	INTO #T
	FROM C



	-- итоговая таблица с плановыми и фактическими показателями
	SELECT * FROM #T
	
	UNION ALL

	SELECT 
		  ManagerID
		, ManagerName
		, ManagerEmail
		, SUM(Plan_ActionsCount) 
		, SUM(Plan_MeetingsCount)
		, MAX(Plan_PaidCompaniesNum)
		, SUM(Plan_Finance)
		, SUM(Plan_Revenue)
		, MAX(Plan_UnqWeight)
		, SUM(Fact_ActionsCount)
		, SUM(Fact_MeetingsCount)
		, MAX(Fact_PaidCompanies) -- TODO: переделать так, чтобы считать не максимум, а значение из последнего месяца
		, SUM(Fact_Finance)
		, SUM(Fact_Revenue)
		, AVG(Fact_UnqWeight) -- TODO: переделать так, чтобы считать не максимум, а значение из последнего месяца
		, IsSuccess
		, 0
		, 'за квартал'
	FROM #T
	GROUP BY 
		  ManagerID
		, ManagerName
		, ManagerEmail
		, IsSuccess
	;

END