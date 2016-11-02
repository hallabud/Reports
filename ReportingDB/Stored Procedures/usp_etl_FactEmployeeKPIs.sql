
CREATE PROCEDURE [dbo].[usp_etl_FactEmployeeKPIs]

AS
 
DECLARE @Date_key INT;
SELECT @Date_key = Date_key FROM Reporting.dbo.DimDate WHERE FullDate = dbo.fnGetDatePart(GETDATE());

INSERT INTO dbo.EmployeeKPIs (Date_key, EmailsWithActiveSubscriptionsNum)
SELECT @Date_key, COUNT(DISTINCT UserEMail)
FROM SRV16.RabotaUA2.dbo.SubscribeCompetitor 
WHERE IsActive = 1;

