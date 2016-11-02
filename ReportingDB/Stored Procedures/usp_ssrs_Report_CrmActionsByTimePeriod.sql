
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-05-04
-- Description:	@TimePeriod - параметр в зависимости от которого группируем данные
--					1 - по дням
--					2 - по неделям
--					3 - по месяцам
--				Процедура возвращает кол-во выполненных действий менеджеров (за исключением тестовых)
--				отдела (DepartmentID) Sales Force, сгруппированных по выбранному временному периоду.
--				Для целей отчета отдельно выделяем тип действия - "Встреча"
-- ======================================================================================================

CREATE PROCEDURE dbo.usp_ssrs_Report_CrmActionsByTimePeriod 
	(@StartDate DATE, @EndDate DATE, @TimePeriod TINYINT)

AS

BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @DateTo DATE = DATEADD(DAY, 1, @EndDate);

	WITH C AS
	 (
	SELECT 
	   D.YearNum
	 , CASE @TimePeriod
		WHEN 1 THEN CONVERT(VARCHAR, D.FullDate, 104) 
		WHEN 2 THEN D.WeekName
		WHEN 3 THEN D.MonthNameEng
	   END AS TimePeriod
	 , CASE @TimePeriod
		WHEN 1 THEN D.Date_key 
		WHEN 2 THEN D.WeekNum
		WHEN 3 THEN D.MonthNum
	   END AS TimeOrder
	 , CASE DIR.Name
		WHEN 'Встреча' THEN 'Встреча'
		ELSE 'Другое'
	   END AS CrmActionType
	 , COUNT(*) AS CrmActionCount
	FROM Analytics.dbo.CRM_Action A
	 JOIN Analytics.dbo.aspnet_Membership MMB ON A.Responsible = MMB.Email
	 JOIN Analytics.dbo.Manager M ON MMB.UserId = M.aspnet_UserUIN
	 JOIN Analytics.dbo.CRM_Directory DIR ON DIR.Type = 'ActionType' AND A.TypeID = DIR.ID
	 JOIN Reporting.dbo.DimDate D ON D.FullDate = CONVERT(DATE, A.CompleteDate)
	WHERE A.CompleteDate BETWEEN @StartDate AND @DateTo
	 AND A.StateID = 2
	 AND M.DepartmentID = 2
	 AND M.IsForTesting = 0
	GROUP BY 
	   D.YearNum
	 , CASE @TimePeriod
		WHEN 1 THEN CONVERT(VARCHAR, D.FullDate, 104) 
		WHEN 2 THEN D.WeekName
		WHEN 3 THEN D.MonthNameEng
	   END
	 , CASE @TimePeriod
		WHEN 1 THEN D.Date_key 
		WHEN 2 THEN D.WeekNum
		WHEN 3 THEN D.MonthNum
	   END
	 , CASE DIR.Name
		WHEN 'Встреча' THEN 'Встреча'
		ELSE 'Другое'
	   END
	 )
	SELECT *
	 , SUM(CrmActionCount) OVER(PARTITION BY YearNum, TimePeriod, TimeOrder) AS CrmActionTotal
	FROM C
	ORDER BY YearNum, TimeOrder, CrmActionType;

END;