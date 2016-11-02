
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-05-19
-- Description:	Процедура возвращает "удельный вес уникальных вакансий", кол-во вакансий, которые нужно 
--				привлечь с ворка для выполнения таргета @Target, кол-во компаний попавших в выборку, 
--				а также кол-во вакансий на работе.юа и кол-во уникальных на ворке, по каждому менеджеру
-- ======================================================================================================
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Modify date: 2016-05-19
-- Description:	Параметр, в который передаем айдишники менеджеров увеличил до VARCHAR(1000)
-- ======================================================================================================

CREATE PROCEDURE dbo.usp_ssrs_Report_UniqueVacancyTarget
	(@CompanyFilter TINYINT,
	 @Target DECIMAL(3,2) = 0.95,
	 @ManagerIDs VARCHAR(1000))

AS

BEGIN

	DECLARE @MayDay DATE = '2016-04-01';
	DECLARE @Today DATE = CONVERT(DATE, GETDATE());
	DECLARE @ThreeMonthAgo DATE = DATEADD(MONTH, -3, @Today);
	DECLARE @Date_key INT = (SELECT Date_key FROM Reporting.dbo.DimDate WHERE FullDate = CONVERT(DATE, GETDATE()));

	WITH C AS
	 (
	SELECT ManagerName, COUNT(Company_key) AS CompanyCount, SUM(VacancyNum) AS VacancyNum, SUM(UnqWorkVacancyNum) AS UnqWorkVacancyNum, 1. * SUM(VacancyNum) / SUM(VacancyNum + UnqWorkVacancyNum) AS UnqWeight
	FROM Reporting.dbo.DimCompany DC
	 JOIN Analytics.dbo.Manager M ON DC.ManagerName = M.Name
	WHERE IndexAttraction > 0
	 AND DepartmentName = 'Sales Force'
	 AND VacancyDiffGroup <> 'R = W = 0'
	 AND WorkConnectionGroup = 'Привязанные компании'
	 AND (ManagerStartDate < CASE WHEN @CompanyFilter = 1 THEN @Today ELSE @MayDay END OR ManagerStartDate < CASE WHEN @CompanyFilter = 1 THEN @Today ELSE @ThreeMonthAgo END) -- Компания взята в работу менеджером или до 1/04/2016, или не позже чем 3 мес. назад
	 AND M.ID IN (SELECT Value FROM dbo.udf_SplitString(@ManagerIDs,','))
	GROUP BY ManagerName
	 )
	SELECT *
	 , CASE 
		WHEN UnqWeight > @Target THEN 0
		ELSE UnqWorkVacancyNum - CAST((VacancyNum - @Target * VacancyNum) / @Target AS INT)
	   END AS DecreaseUnqWorkVacancy
	FROM C
	ORDER BY UnqWeight DESC;

END