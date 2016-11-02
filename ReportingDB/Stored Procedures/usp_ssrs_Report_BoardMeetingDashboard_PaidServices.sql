CREATE PROCEDURE [dbo].[usp_ssrs_Report_BoardMeetingDashboard_PaidServices]
	@YearNum INT, @Mode TINYINT

AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

IF @Mode = 1
	
	BEGIN

	SELECT 'rabota.ua' AS Website, D.YearNum, D.MonthNum, D.MonthNameEng, COUNT(DISTINCT FCS.Company_key) AS NotebookCount
	FROM Reporting.dbo.FactCompanyStatuses FCS WITH (NOLOCK)
	 JOIN Reporting.dbo.DimDate D ON FCS.Date_key = D.Date_key
	WHERE D.DayNum = 1
	 AND FCS.HasPaidServices = 1
	 AND D.YearNum = @YearNum
	GROUP BY D.YearNum, D.MonthNum, D.MonthNameEng

	UNION ALL

	SELECT 'work.ua' AS Website,  D0.YearNum, D0.MonthNum, D0.MonthNameEng, COUNT(DISTINCT FSCI.SpiderCompanyID) AS NotebookCount
	FROM Reporting.dbo.FactSpiderCompanyIndexes FSCI WITH (NOLOCK)
	 JOIN Reporting.dbo.DimDate D ON FSCI.Date_key = D.Date_key
	 JOIN Reporting.dbo.DimDate D0 ON FSCI.Date_key - 1 = D0.Date_key
	WHERE D.DayNum = 1
	 -- дивная логика определения платного клиента на ворке вызвана кривизной спайдеров, связанных с ним подсистем или постановкой задачи на логику спайдеров
	 AND ((FSCI.IsBusiness = 1 AND FSCI.VacancyCount > 3) OR (FSCI.IsBusiness = 0 AND FSCI.VacancyCount > 1) OR FSCI.IsBusiness | FSCI.IsPaidByTickets | FSCI.Paid | FSCI.IsHasLogo | FSCI.IsHasLogo_OnMain = 1 OR FSCI.HotVacancyCount > 0)
	 AND D.YearNum = @YearNum
	GROUP BY D0.YearNum, D0.MonthNum, D0.MonthNameEng

	ORDER BY Website, YearNum, MonthNum;

	END

IF @Mode = 2

	BEGIN

	WITH C AS
	 (
	SELECT 'rabota.ua' AS Website,  D.YearNum, D.MonthNum, D.MonthNameEng, COUNT(DISTINCT FCS.Company_key) AS NotebookCount
	 , ROW_NUMBER() OVER(ORDER BY D.YearNum DESC, D.MonthNum DESC) AS RowNum
	FROM Reporting.dbo.FactCompanyStatuses FCS WITH (NOLOCK)
	 JOIN Reporting.dbo.DimDate D ON FCS.Date_key = D.Date_key
	WHERE D.IsLastDayOfMonth = 1
	 AND FCS.HasPaidServices = 1
	 AND D.YearNum BETWEEN @YearNum - 1 AND @YearNum
	GROUP BY D.YearNum, D.MonthNum, D.MonthNameEng

	UNION ALL

	SELECT 'work.ua' AS Website,  D0.YearNum, D0.MonthNum, D0.MonthNameEng, COUNT(DISTINCT FSCI.SpiderCompanyID) AS NotebookCount
	 , ROW_NUMBER() OVER(ORDER BY D0.YearNum DESC, D0.MonthNum DESC) AS RowNum
	FROM Reporting.dbo.FactSpiderCompanyIndexes FSCI WITH (NOLOCK)
	 JOIN Reporting.dbo.DimDate D ON FSCI.Date_key = D.Date_key
	 JOIN Reporting.dbo.DimDate D0 ON FSCI.Date_key - 1 = D0.Date_key
	WHERE D.DayNum = 1
	 -- дивная логика определения платного клиента на ворке вызвана кривизной спайдеров, связанных с ним подсистем или постановкой задачи на логику спайдеров
	 AND ((FSCI.IsBusiness = 1 AND FSCI.VacancyCount > 3) OR (FSCI.IsBusiness = 0 AND FSCI.VacancyCount > 1) OR FSCI.IsBusiness | FSCI.IsPaidByTickets | FSCI.Paid | FSCI.IsHasLogo | FSCI.IsHasLogo_OnMain = 1 OR FSCI.HotVacancyCount > 0)
	 AND D.YearNum BETWEEN @YearNum - 1 AND @YearNum
	GROUP BY D0.YearNum, D0.MonthNum, D0.MonthNameEng
	 )

	SELECT * 
	FROM C	
	WHERE RowNum BETWEEN 1 AND 12
	ORDER BY Website, YearNum, MonthNum;

	END