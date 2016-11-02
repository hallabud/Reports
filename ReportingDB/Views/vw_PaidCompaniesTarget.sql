

CREATE VIEW [dbo].[vw_PaidCompaniesTarget]

AS

SELECT
	  DD.FullDate
	, DD.DayNum
	, DD.WeekDayNum
	, DC.ManagerName
	, DC.DepartmentName
	, DC.NotebookId
	, DC.CompanyName
	, DC.IndexAttraction 
	, CASE
	WHEN FCS.HasPaidPublishedVacs = 1 OR FCS.HasPaidPublicationsLeft = 1 OR FCS.HasHotPublishedVacs = 1 OR FCS.HasHotPublicationsLeft = 1 OR FCS.HasCVDBAccess = 1 OR FCS.HasActivatedLogo = 1 OR FCS.HasActivatedProfile = 1 THEN 'Клиент'
	ELSE 'Не клиент'
	END AS IsClient
	, CASE 
	WHEN NC.IsNetworkCompany = 1 OR NC.IsNonResident = 1 OR NC.HeadquarterCityId IN (SELECT Id FROM Analytics.dbo.City WHERE Id IN (6,12,13,29,33,34) OR OblastCityID IN (6,12,13,29,33,34)) THEN 'Нецелевые компании'
	ELSE 'Целевые компании'
	END AS IsTargetAudience
	, CASE 
	WHEN DC.AvgLast3Month > 5 THEN 'Высокая'
	WHEN DC.AvgLast3Month BETWEEN 3 AND 5 THEN 'Средняя'
	WHEN DC.AvgLast3Month BETWEEN 1.66 AND 3 THEN 'Низкая'
	ELSE 'Непонятная'
	END AS Demand
	, CASE 
	WHEN DC.AvgLast3Month >= 1.66 THEN 'Больше 1,66'
	ELSE 'Меньше 1,6' 
	END AS Demand2	
FROM Reporting.dbo.DimCompany DC
	JOIN Reporting.dbo.FactCompanyStatuses FCS ON DC.Company_key = FCS.Company_key
	JOIN Reporting.dbo.DimDate DD ON FCS.Date_key = DD.Date_key
	JOIN Analytics.dbo.NotebookCompany NC ON DC.NotebookId = NC.NotebookId
WHERE (DD.DayNum = 1 OR DD.WeekDayNum = 6 OR DD.FullDate = dbo.fnGetDatePart(GETDATE()))

