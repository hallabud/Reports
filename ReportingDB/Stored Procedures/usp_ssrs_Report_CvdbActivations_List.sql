-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-02-23
-- Description:	Процедура возвращает список заказов, по которым было начисление сервиса "Доступ к CVDB" 
-- ======================================================================================================

CREATE PROCEDURE [dbo].[usp_ssrs_Report_CvdbActivations_List]
	@StartDate DATE, 
	@EndDate DATE

AS

BEGIN

	WITH C AS
	 (
	SELECT O.NotebookID, NC.Name AS NotebookName, M.Name AS ManagerName, OD.OrderID, OD.ActivationStartDate, OD.ActivationEndDate, DIR.Name AS OrderType, SUM(OD.ClientPrice) AS ClientPrice
	FROM Analytics.dbo.OrderDetail OD
	 JOIN Analytics.dbo.Orders O ON OD.OrderID = O.ID
	 JOIN Analytics.dbo.NotebookCompany NC ON O.NotebookID = NC.NotebookId
	 JOIN Analytics.dbo.Manager M ON NC.ManagerId = M.Id
	 JOIN Analytics.dbo.Directory DIR ON DIR.Type = N'OrderType' AND DIR.ID = O.Type
	WHERE OD.ServiceID = 4
	 AND OD.ActivationStartDate BETWEEN @StartDate AND @EndDate
	 AND OD.State IN (2,3)
	GROUP BY O.NotebookID, NC.Name, M.Name, OD.OrderID, OD.ActivationStartDate, OD.ActivationEndDate, DIR.Name
	 )
	SELECT * 
	 , (SELECT COUNT(*) FROM Analytics.dbo.NotebookCompanyResumeView WHERE NotebookID = C.NotebookID AND AddDate BETWEEN C.ActivationStartDate AND Reporting.dbo.fnGetMinimumOf2ValuesDate(@EndDate, C.ActivationEndDate)) AS ResumeViewed
	 , (SELECT COUNT(*) FROM Analytics.dbo.DailyViewedResume DVR WHERE EmployerNotebookID = C.NotebookId AND ViewDate BETWEEN C.ActivationStartDate AND Reporting.dbo.fnGetMinimumOf2ValuesDate(@EndDate, C.ActivationEndDate)) AS ContactsOpened
	FROM C
	ORDER BY ActivationStartDate, NotebookID;

END