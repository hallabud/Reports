
CREATE PROCEDURE [dbo].[usp_ssrs_ReportRecognizedRevenueNotebook]
 @StartDate DATETIME, @EndDate DATETIME

AS

SELECT 
   DS.Service_key
 , DS.ServiceName
 , DS.ServiceGroup
 , DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.MonthNameEng
 , DD.WeekNum
 , DD.WeekName
 , NC.NotebookID
 , NC.Name AS CompanyName
 , D.Name AS Department
 , C.Name AS City
 , SUM(FRR.RecognizedRevenue) AS RecognizedRevenue
FROM Reporting.dbo.FactRecognizedRevenueNotebook FRR
 JOIN Reporting.dbo.DimDate DD ON FRR.Date_key = DD.Date_key
 JOIN Reporting.dbo.DimService DS ON FRR.Service_key = DS.Service_key
 LEFT JOIN Analytics.dbo.NotebookCompany NC ON FRR.NotebookID = NC.NotebookID
 LEFT JOIN Analytics.dbo.City C ON NC.HeadquarterCityID = C.Id
 LEFT JOIN Analytics.dbo.Manager M ON NC.ManagerID = M.ID
 LEFT JOIN Analytics.dbo.Departments D ON M.DepartmentID = D.Id
WHERE DD.FullDate BETWEEN @StartDate AND @EndDate
GROUP BY 
   DS.Service_key
 , DS.ServiceName
 , DS.ServiceGroup
 , DD.YearNum
 , DD.MonthNum
 , DD.MonthNameRus
 , DD.MonthNameEng
 , DD.WeekNum
 , DD.WeekName
 , NC.NotebookID
 , NC.Name
 , D.Name
 , C.Name;