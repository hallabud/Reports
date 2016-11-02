


CREATE PROCEDURE [dbo].[usp_ssrs_Report_HotPublicationsSpent] 
	(@ManagerIDs NVARCHAR(1000))

AS

SELECT 
    NCS.NotebookID
  , NCS.ID AS NotebookCompany_SpentID
  , D.FullDate
  , D.YearNum
  , D.MonthNum
  , D.MonthNameEng AS 'Месяц'
  , NCS.SpendCount AS 'Кол-во публикаций'
  , CAST(TP.SummHot / TP.VacancyHot AS DECIMAL(18,2)) AS 'Стоимость 1-й публикации'
  , NC.ManagerId
  , M.Name AS ManagerName
  , COALESCE(TL.ID, M.ID) AS TeamLeadManagerID
  , COALESCE(TL.Name, M.Name) AS TeamLeadManagerName
FROM Analytics.dbo.NotebookCompany_Spent NCS
 JOIN Analytics.dbo.TicketPayment TP ON NCS.TicketPaymentID = TP.ID
 JOIN Reporting.dbo.DimDate D ON CAST(NCS.AddDate AS DATE) = D.FullDate
 JOIN Analytics.dbo.NotebookCompany NC ON NCS.NotebookID = NC.NotebookId
 JOIN Analytics.dbo.Manager M ON NC.ManagerId = M.Id
 LEFT JOIN Analytics.dbo.Manager TL ON M.TeamLead_ManagerID = TL.ID
WHERE SpendType = 5
 AND NC.ManagerId IN (SELECT Value FROM dbo.udf_SplitString(@ManagerIDs, ','));


