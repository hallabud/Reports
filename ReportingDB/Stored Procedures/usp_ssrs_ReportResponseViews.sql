
CREATE PROCEDURE [dbo].[usp_ssrs_ReportResponseViews]

AS

DECLARE @VacancyPubEndDate DATETIME; SET @VacancyPubEndDate = DATEADD(DAY,-14,dbo.fnGetDatePart(GETDATE()));
DECLARE @VacancyPubStartDate DATETIME; SET @VacancyPubStartDate = DATEADD(DAY,-14,@VacancyPubEndDate);
DECLARE @ResponsesStartDate DATETIME; SET @ResponsesStartDate = @VacancyPubStartDate;



WITH CTE_Responses AS
 (
SELECT
   'Apply' AS ResponseSrc
 , VATV.NotebookID
 , NC.SegmentCategory
 , VATV.ID
 , VATV.VacancyID
 , VATV.AddDate
 , VATV.ViewedDate
FROM Analytics.dbo.VacancyApplyToVacancy VATV
 JOIN Analytics.dbo.VacancyPublished VP ON VATV.VacancyId = VP.ID
 JOIN Analytics.dbo.NotebookCompany NC ON VATV.NotebookId = NC.NotebookId
WHERE VATV.AddDate >= VP.StateDate AND VATV.AddDate >= @ResponsesStartDate
 AND VP.StateDate BETWEEN @VacancyPubStartDate AND @VacancyPubEndDate
UNION ALL
SELECT
   'ProfResume'
 , RTV.NotebookId
 , NC.SegmentCategory
 , RTV.ID
 , RTV.VacancyID
 , RTV.AddDate
 , RTV.ViewedDate
FROM Analytics.dbo.ResumeToVacancy RTV
 JOIN Analytics.dbo.VacancyPublished VP ON RTV.VacancyId = VP.ID
 JOIN Analytics.dbo.NotebookCompany NC ON RTV.NotebookId = NC.NotebookId
WHERE RTV.AddDate >= VP.StateDate AND RTV.AddDate >= @ResponsesStartDate
 AND VP.StateDate BETWEEN @VacancyPubStartDate AND @VacancyPubEndDate
 )
 , CTE_ViewedTimes AS 
 (
SELECT
   ResponseSrc
 , ID
 , NotebookId
 , SegmentCategory
 , VacancyID
 , AddDate
 , ViewedDate
 , CASE 
    WHEN DATEDIFF(DAY,AddDate,ViewedDate) IS NULL OR DATEDIFF(DAY,AddDate,ViewedDate) < 0 THEN '0.Непросмотренный'
    WHEN DATEDIFF(DAY,AddDate,ViewedDate) = 0 THEN '1.Просмотрено в день отклика'
    WHEN DATEDIFF(DAY,AddDate,ViewedDate) = 1 THEN '2.Просмотрено на следующий день'
    WHEN DATEDIFF(DAY,AddDate,ViewedDate) = 2 THEN '3.Просмотрено на 3-й день'
    WHEN DATEDIFF(DAY,AddDate,ViewedDate) = 3 THEN '4.Просмотрено на 4-й день'
    WHEN DATEDIFF(DAY,AddDate,ViewedDate) = 4 THEN '5.Просмотрено на 5-й день'
    WHEN DATEDIFF(DAY,AddDate,ViewedDate) BETWEEN 5 AND 10 THEN '6.Просмотрено между 6-м и 10-м днем после отклика'
    WHEN DATEDIFF(DAY,AddDate,ViewedDate) > 10 THEN '7.Просмотрено более, чем через 10 дней после отклика'
    ELSE '9.Other'
   END AS TimeInterval    
FROM CTE_Responses
 )
 , CTE_VacancyLastSpentDates AS
 (
SELECT
   NCS.VacancyID
 , MAX(NCS.AddDate) AS VacancyLastPaymentDate
FROM Analytics.dbo.NotebookCompany_Spent NCS
WHERE EXISTS (SELECT * FROM Analytics.dbo.VacancyPublished VP WHERE VP.ID = NCS.VacancyId)
GROUP BY NCS.VacancyID
 )
, CTE_VacancyPublishedDetails AS
 (
SELECT 
   NCS.VacancyId
 , CASE 
    WHEN NCS.SpendType <> 4 THEN 'Платная публикация'
    WHEN ISNULL(RTP.TicketPaymentTypeId,0) <> 6 THEN 'Платная публикация'
    ELSE 'Бесплатная публикация' 
   END AS IsPaid
FROM Analytics.dbo.NotebookCompany_Spent NCS
 LEFT JOIN Analytics.dbo.RegionalTicketPayment RTP ON NCS.TicketPaymentID = RTP.ID AND NCS.RegionalPackageID = 18
WHERE EXISTS (SELECT * FROM CTE_VacancyLastSpentDates VLSD WHERE VLSD.VacancyID = NCS.VacancyId AND VLSD.VacancyLastPaymentDate = NCS.AddDate) 
 )
SELECT 
   VPD.IsPaid
 , VT.TimeInterval
 , COUNT(*) AS RespCount
FROM CTE_VacancyPublishedDetails VPD
 JOIN CTE_ViewedTimes VT ON VPD.VacancyId = VT.VacancyId
GROUP BY 
   VPD.IsPaid
 , VT.TimeInterval
ORDER BY VT.TimeInterval, VPD.IsPaid;



