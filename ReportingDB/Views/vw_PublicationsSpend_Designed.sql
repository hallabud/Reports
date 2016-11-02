

CREATE VIEW [dbo].[vw_PublicationsSpend_Designed]

AS	

SELECT 
   NCS.NotebookID
 , NCS.ID AS NotebookCompany_SpentID
 , D.FullDate
 , D.YearNum
 , D.MonthNum
 , D.MonthNameEng AS 'Месяц'
 , NCS.SpendCount AS 'Кол-во публикаций'
 , CAST(TP.SummDesigned / NULLIF(TP.VacancyDesigned,0) AS DECIMAL(18,2)) AS 'Стоимость 1-й публикации'
FROM Analytics.dbo.NotebookCompany_Spent NCS
 JOIN Analytics.dbo.TicketPayment TP ON NCS.TicketPaymentID = TP.ID
 JOIN Reporting.dbo.DimDate D ON CONVERT(DATE, NCS.AddDate) = D.FullDate
WHERE SpendType = 2;

