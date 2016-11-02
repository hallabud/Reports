
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-07-06
-- Description:	Процедура возвращает в разрезе выбранного периода удельный вес вакансий на работа.уа
--				в общем кол-ве вакансий
-- ======================================================================================================

CREATE PROCEDURE dbo.usp_ssrs_Report_UniqueVacancyAverage 
	(@StartDate DATE, 
	 @EndDate DATE, 
	 @ManagerEmails NVARCHAR(MAX),
	 @Mode TINYINT,
	 @CompanyFilter TINYINT)

AS

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


--@CompanyFilter
--1 - Все компании
--2 - Без учета компаний 3 мес. на установление лояльности

-- @Mode
-- 1 - месячный
-- 2 - недельный

DECLARE @Today DATE = CONVERT(DATE, GETDATE());
DECLARE @ThreeMonthAgo DATE = DATEADD(MONTH, -3, @Today);

SELECT 
   D.YearNum
 , CASE @Mode WHEN 1 THEN D.MonthNum WHEN 2 THEN D.WeekNum END AS PeriodNum
 , CASE @Mode WHEN 1 THEN D.MonthNameRus WHEN 2 THEN D.WeekName END AS PeriodName
 , AVG(1. * CS.VacancyNum / NULLIF((CS.VacancyNum + ISNULL(CS.UnqWorkVacancyNum,0)),0)) AS AvgUnqVacancyWeight
FROM dbo.FactCompanyStatuses CS
 JOIN dbo.DimDate D ON D.Date_key = CS.Date_key 
 JOIN dbo.DimCompany C ON C.Company_key = CS.Company_key
WHERE D.FullDate BETWEEN @StartDate AND @EndDate
 AND C.WorkConnectionGroup = 'Привязанные компании'
 AND C.ManagerEmail IN (SELECT [Value] FROM dbo.udf_SplitString(@ManagerEmails,','))
 AND C.ManagerStartDate <= CASE WHEN @CompanyFilter = 1 THEN @Today ELSE @ThreeMonthAgo END
GROUP BY 
   D.YearNum
 , CASE @Mode WHEN 1 THEN D.MonthNum WHEN 2 THEN D.WeekNum END
 , CASE @Mode WHEN 1 THEN D.MonthNameRus WHEN 2 THEN D.WeekName END
ORDER BY 
   D.YearNum
 , PeriodNum;

