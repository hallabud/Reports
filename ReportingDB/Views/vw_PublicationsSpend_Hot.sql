

CREATE VIEW [dbo].[vw_PublicationsSpend_Hot]

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
FROM Analytics.dbo.NotebookCompany_Spent NCS
 JOIN Analytics.dbo.TicketPayment TP ON NCS.TicketPaymentID = TP.ID
 JOIN Reporting.dbo.DimDate D ON CAST(NCS.AddDate AS DATE) = D.FullDate
 JOIN Analytics.dbo.NotebookCompany NC ON NCS.NotebookID = NC.NotebookId
WHERE SpendType = 5;

