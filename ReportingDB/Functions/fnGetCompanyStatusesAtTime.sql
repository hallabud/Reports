
CREATE FUNCTION [dbo].[fnGetCompanyStatusesAtTime] 
(
	@NotebookId INT,
    @Date DATETIME
)
RETURNS 
@CompanyStatuses TABLE 
(
	NotebookId INT,
    StatusName VARCHAR(50),
    StatusValue BIT
)
AS
BEGIN

DECLARE @DateDay INT; SET @DateDay = dbo.fnDayByDate(@Date);
		
	-- наличие опубликованных вакансий по состоянию на дату
    INSERT INTO @CompanyStatuses
	SELECT @NotebookId
     , 'HasPaidPublishedVacs' AS 'Field'
	 , CASE WHEN COUNT(*) >= 1 THEN 1 ELSE 0 END AS 'Value'
	FROM SRV16.RabotaUA2.dbo.VacancyStateHistory VSH
	 JOIN SRV16.RabotaUA2.dbo.NotebookCompany_Spent NCS ON VSH.VacancyId = NCS.VacancyId
	 LEFT JOIN SRV16.RabotaUA2.dbo.RegionalTicketPayment RTP ON NCS.TicketPaymentID = RTP.Id AND NCS.RegionalPackageID = 18
	WHERE VSH.State = 4
	 AND ABS(DATEDIFF(MINUTE,VSH.DateTime,NCS.AddDate)) = 0
	 AND ISNULL(RTP.TicketPaymentTypeID,0) <> 6
	 AND NCS.NotebookId = @NotebookId
	 AND @DateDay >= VSH.DateFrom AND (VSH.DateTo IS NULL  OR VSH.DateTo >= @DateDay)

	UNION ALL

	-- наличие оставшихся платных публикаций (тикетов) по состоянию на дату
	SELECT @NotebookId
     , 'HasPaidPublicationsLeft' AS 'Field'
	 , CASE WHEN SUM(NewValue) >= 1 THEN 1 ELSE 0 END
	FROM 
		(SELECT NewValue, ROW_NUMBER() OVER (PARTITION BY Field ORDER BY DateOfUpd DESC) AS Number
		 FROM SRV16.RabotaUA2.dbo.NotebookCompany_History
		  WHERE Field IN ('rtVacancyStandart','rtVacancyDesigned')
		   AND NotebookId = @NotebookId
		   AND DateOfUpd <= @Date) AS A
	WHERE Number = 1
	
	UNION ALL

    -- наличие опубликованных горячих вакансий по состоянию на дату
	SELECT @NotebookId
     , 'HasHotPublishedVacs' AS 'Field'
	 , CASE WHEN COUNT(*) >= 1 THEN 1 ELSE 0 END
	FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent NCS
	WHERE SpendType = 5
	 AND NotebookId = @NotebookId
	 AND @Date BETWEEN NCS.AddDate AND DATEADD(DAY, 7 * NCS.SpendCount, NCS.AddDate)

	UNION ALL

    -- наличие оставшихся горячих публикаций (тикетов) по состоянию на дату
	SELECT @NotebookId
     , 'HasHotPublicationsLeft' AS 'Field'
	 , CASE WHEN SUM(NewValue) >= 1 THEN 1 ELSE 0 END
	FROM 
		(SELECT NewValue, ROW_NUMBER() OVER (PARTITION BY Field ORDER BY DateOfUpd DESC) AS Number
		 FROM SRV16.RabotaUA2.dbo.NotebookCompany_History
		  WHERE Field = 'rtVacancyHot'
		   AND NotebookId = @NotebookId
		   AND DateOfUpd <= @Date
		 UNION ALL 
		 SELECT 0, 1) AS A
	WHERE Number = 1

	UNION ALL

    -- наличие доступа к CVDB по состоянию на дату
	SELECT @NotebookId
     , 'HasCVDBAccess' AS 'Field'
	 , CASE WHEN COUNT(*) >= 1 THEN 1 ELSE 0 END
	FROM SRV16.RabotaUA2.dbo.TemporalPayment TP
	WHERE TP.NotebookID = @NotebookID 
	 AND @Date BETWEEN TP.StartDate AND TP.EndDate AND Price > 0

	UNION ALL

    -- наличие актвивированного логотипа
	SELECT @NotebookId
     , 'HasActivatedLogo' AS 'Field'
	 , CASE WHEN COUNT(*) >= 1 THEN 1 ELSE 0 END
	FROM SRV16.RabotaUA2.dbo.OrderDetail OD
	 JOIN SRV16.RabotaUA2.dbo.Orders O ON OD.OrderID = O.ID
	WHERE O.NotebookID = @NotebookID
	 AND OD.ServiceID BETWEEN 27 AND 46
	 AND @Date BETWEEN OD.ActivationStartDate AND OD.ActivationEndDate
	
	UNION ALL
	
    -- наличие активированного профиля
	SELECT @NotebookId
     , 'HasActivatedProfile' AS 'Field'
	 , CASE WHEN COUNT(*) >= 1 THEN 1 ELSE 0 END
	FROM SRV16.RabotaUA2.dbo.OrderDetail OD
	 JOIN SRV16.RabotaUA2.dbo.Orders O ON OD.OrderID = O.ID
	WHERE O.NotebookID = @NotebookID
	 AND OD.ServiceID IN (25,26)
	 AND @Date BETWEEN OD.ActivationStartDate AND OD.ActivationEndDate;

	RETURN
END
