CREATE PROCEDURE [dbo].[usp_ssrs_Report_BoardMeetingDashboard_PaidServicesStructure]
	@YearNum INT, @Mode TINYINT

AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

IF @Mode = 1
	
	BEGIN

	SELECT D0.YearNum, D0.MonthNum, D0.MonthNameEng
	 , CASE
	    WHEN FSCI.IsBusiness = 0 THEN 'Other service only'
		WHEN FSCI.VacancyCount > 3 THEN 'Business Placement + Other'
		ELSE 'Business Placement Only'
	   END AS PaidServiceGroup
	 , COUNT(DISTINCT FSCI.SpiderCompanyID) AS NotebookCount
	FROM Reporting.dbo.FactSpiderCompanyIndexes FSCI WITH (NOLOCK)
	 JOIN Reporting.dbo.DimDate D ON FSCI.Date_key = D.Date_key
	 JOIN Reporting.dbo.DimDate D0 ON FSCI.Date_key - 1 = D0.Date_key
	WHERE D.DayNum = 1
	 -- дивная логика определения платного клиента на ворке вызвана кривизной спайдеров, связанных с ним подсистем или постановкой задачи на логику спайдеров
	 AND ((FSCI.IsBusiness = 1 AND FSCI.VacancyCount > 3) OR (FSCI.IsBusiness = 0 AND FSCI.VacancyCount > 1) OR FSCI.IsBusiness | FSCI.IsPaidByTickets | FSCI.Paid | FSCI.IsHasLogo | FSCI.IsHasLogo_OnMain = 1 OR FSCI.HotVacancyCount > 0)
	 AND D.YearNum = @YearNum
	GROUP BY D0.YearNum
	 , D0.MonthNum
	 , D0.MonthNameEng
	 , CASE
	    WHEN FSCI.IsBusiness = 0 THEN 'Other service only'
		WHEN  FSCI.VacancyCount > 3 THEN 'Business Placement + Other'
		ELSE 'Business Placement Only'
	   END

	ORDER BY YearNum, MonthNum;

	END

IF @Mode = 2

	BEGIN

	WITH C AS
	 (
	SELECT D0.YearNum, D0.MonthNum, D0.MonthNameEng
	 , CASE
	    WHEN FSCI.IsBusiness = 0 THEN 'Other service only'
		WHEN FSCI.VacancyCount > 3 THEN 'Business Placement + Other'
		ELSE 'Business Placement Only'
	   END AS PaidServiceGroup
	 , COUNT(DISTINCT FSCI.SpiderCompanyID) AS NotebookCount
	 , ROW_NUMBER() OVER(ORDER BY D0.YearNum DESC, D0.MonthNum DESC) AS RowNum
	FROM Reporting.dbo.FactSpiderCompanyIndexes FSCI WITH (NOLOCK)
	 JOIN Reporting.dbo.DimDate D ON FSCI.Date_key = D.Date_key
	 JOIN Reporting.dbo.DimDate D0 ON FSCI.Date_key - 1 = D0.Date_key
	WHERE D.DayNum = 1
	 -- дивная логика определения платного клиента на ворке вызвана кривизной спайдеров, связанных с ним подсистем или постановкой задачи на логику спайдеров
	 AND ((FSCI.IsBusiness = 1 AND FSCI.VacancyCount > 3) OR (FSCI.IsBusiness = 0 AND FSCI.VacancyCount > 1) OR FSCI.IsBusiness | FSCI.IsPaidByTickets | FSCI.Paid | FSCI.IsHasLogo | FSCI.IsHasLogo_OnMain = 1 OR FSCI.HotVacancyCount > 0)
	 AND D.YearNum BETWEEN @YearNum - 1 AND @YearNum
	GROUP BY D0.YearNum, D0.MonthNum, D0.MonthNameEng
	 , CASE
	    WHEN FSCI.IsBusiness = 0 THEN 'Other service only'
		WHEN FSCI.VacancyCount > 3 THEN 'Business Placement + Other'
		ELSE 'Business Placement Only'
	   END
	 )

	SELECT * 
	FROM C	
	WHERE RowNum BETWEEN 1 AND 36
	ORDER BY YearNum, MonthNum;

	END