
CREATE PROCEDURE [dbo].[usp_IsActive6] (@NotebookId INT)

AS

DECLARE @Date_key INT; SELECT @Date_key = Date_key FROM dbo.DimDate WHERE FullDate = dbo.fnGetDatePart(GETDATE());

SELECT COUNT(*) AS IsActive6
FROM dbo.FactCompanyStatuses CS
 JOIN dbo.DimCompany C ON CS.Company_key = C.Company_key
WHERE (CS.PublicationsNumLast6Months >= 2 AND CS.MonthsNumLast6Months >= 2 AND CS.PublicationsNumLast3Months >= 1)
 AND CS.Date_key = @Date_key
 AND C.NotebookId = @NotebookId
;