
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-05-19
-- Description:	Процедура возвращает список компаний с данными необходимыми для построения отчета
--				"Number of Clients with Paid Services by Months"
-- ======================================================================================================

CREATE PROCEDURE dbo.usp_ssrs_Report_NumberOfClientsWithPaidServicesByMonths
	(@StartDate DATE, 
	 @EndDate DATE, 
	 @BranchIDs VARCHAR(1000), 
	 @ManagerIDs VARCHAR(1000))

AS

BEGIN

	DECLARE @TodayDate DATETIME = dbo.fnGetDatePart(GETDATE());

	SELECT
	   CS.Company_key
	 , NC.Name AS 'CompanyName'
	 , NC.HeadQuarterCityID
	 , M.Name AS 'ManagerName'
	 , M.Id AS ManagerID
	 , DD.YearNum
	 , DD.MonthNameRus
	 , DD.MonthNum
	 , DD.FullDate
	 , CASE 
		WHEN HasPaidPublishedVacs | HasPaidPublicationsLeft = 1 THEN 'Есть платные публикации на счету или опубликованные платные вакансии'
		WHEN HasHotPublishedVacs | HasHotPublicationsLeft = 1 THEN 'Есть горячие публикации на счету или опубликованные горячие вакансии'
		WHEN HasCVDBAccess = 1 THEN 'Есть доступ к базе резюме'
		WHEN HasActivatedLogo | HasActivatedProfile = 1 THEN 'Клиенты по другому сервису (профиль/логотип)'
		ELSE 'Не использовали платный сервис'
	   END AS 'CompanyGroup'
	 , CASE 
		WHEN HasPaidPublishedVacs | HasPaidPublicationsLeft = 1 THEN 'green'
		WHEN HasHotPublishedVacs | HasHotPublicationsLeft = 1 THEN 'orange'
		WHEN HasCVDBAccess = 1 THEN 'blue'
		WHEN HasActivatedLogo | HasActivatedProfile = 1 THEN 'yellow'
		ELSE 'red'
	   END AS 'CardColor'
	FROM Reporting.dbo.DimCompany DC
	 JOIN Analytics.dbo.NotebookCompany NC ON DC.NotebookId = NC.NotebookId
	 JOIN Analytics.dbo.Manager M ON NC.ManagerId = M.Id
	 JOIN Reporting.dbo.FactCompanyStatuses CS ON DC.Company_key = CS.Company_key
	 JOIN Reporting.dbo.DimDate DD ON CS.Date_key = DD.Date_key
	WHERE DD.FullDate BETWEEN @StartDate AND @EndDate
	 AND (DD.DayNum = 1 OR DD.FullDate = @TodayDate)
	 AND NOT EXISTS (SELECT * FROM Analytics.dbo.NotebookCompanyMerged WHERE SourceNotebookID = NC.NotebookID)
	 AND NC.IsNetworkCompany = 0
	 AND NC.BranchID IN (SELECT Value FROM dbo.udf_SplitString(@BranchIDs, ','))
	 AND M.ID IN (SELECT Value FROM dbo.udf_SplitString(@ManagerIDs, ','))
	 AND EXISTS (SELECT * 
				 FROM Reporting.dbo.FactCompanyStatuses CS2
				  JOIN Reporting.dbo.DimDate DD2 ON CS2.Date_key = DD2.Date_key
				 WHERE CS2.Company_key = CS.Company_key 
				  AND DD2.FullDate BETWEEN DATEADD(MONTH, -12, DD.FullDate) AND DD.FullDate
				  AND HasPaidServices = 1)

END