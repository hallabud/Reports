
CREATE FUNCTION [dbo].[fnGetCompanyStatuses] 
(
	@NotebookId INT
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
	DECLARE @TodayDate DATETIME; SET @TodayDate = dbo.fnGetDatePart(GETDATE());	
	
	INSERT INTO @CompanyStatuses
	SELECT @NotebookId
     , 'HasPaidPublishedVacs' AS 'Field'
	 , CASE WHEN COUNT(*) >= 1 THEN 1 ELSE 0 END AS 'Value'
	FROM SRV16.RabotaUA2.dbo.VacancyPublished VP
	WHERE NotebookId = @NotebookId
	 AND NOT
	 (ISNULL(RegionalPackageID, '') = '18' 
	   AND 
	  ISNULL((SELECT TOP 1 R.TicketPaymentTypeID 
			  FROM SRV16.RabotaUA2.dbo.RegionalTicketPayment R 
			   JOIN SRV16.RabotaUA2.dbo.NotebookCompany_Spent S ON S.TicketPaymentID = R.ID
			  WHERE S.VacancyID = VP.ID ORDER BY S.ID DESC), 0) = 6)

	UNION ALL

	SELECT @NotebookId
     , 'HasPaidPublicationsLeft' AS 'Field'
	 , CASE WHEN COUNT(*) >= 1 THEN 1 ELSE 0 END
	FROM SRV16.RabotaUA2.dbo.NotebookCompany NC
	WHERE NC.NotebookID = @NotebookID 
	 AND (NC.rtVacancyStandart > 0 OR NC.rtVacancyDesigned > 0)

	UNION ALL

	SELECT @NotebookId
     , 'HasHotPublishedVacs' AS 'Field'
	 , CASE WHEN COUNT(*) >= 1 THEN 1 ELSE 0 END
	FROM SRV16.RabotaUA2.dbo.VacancyPublished VP
	 JOIN SRV16.RabotaUA2.dbo.VacancyExtra VE ON VP.ID = VE.VacancyID
	WHERE NotebookId = @NotebookId
	 AND @TodayDate BETWEEN VE.HotStartDate AND VE.HotEndDate + 1

	UNION ALL

	SELECT @NotebookId
     , 'HasHotPublicationsLeft' AS 'Field'
	 , CASE WHEN COUNT(*) >= 1 THEN 1 ELSE 0 END
	FROM SRV16.RabotaUA2.dbo.NotebookCompany NC
	WHERE NC.NotebookID = @NotebookID 
	 AND NC.rtVacancyHot > 0

	UNION ALL

	SELECT @NotebookId
     , 'HasCVDBAccess' AS 'Field'
	 , CASE WHEN COUNT(*) >= 1 THEN 1 ELSE 0 END
	FROM SRV16.RabotaUA2.dbo.TemporalPayment TP
	WHERE TP.NotebookID = @NotebookID 
	 AND @TodayDate BETWEEN TP.StartDate AND TP.EndDate AND Price > 0

	UNION ALL

	SELECT @NotebookId
     , 'HasActivatedLogo' AS 'Field'
	 , CASE WHEN COUNT(*) >= 1 THEN 1 ELSE 0 END
	FROM SRV16.RabotaUA2.dbo.OrderDetail OD
	 JOIN SRV16.RabotaUA2.dbo.Orders O ON OD.OrderID = O.ID
	WHERE O.NotebookID = @NotebookID
	 AND OD.ServiceID BETWEEN 27 AND 46
	 AND @TodayDate BETWEEN OD.ActivationStartDate AND OD.ActivationEndDate
	
	UNION ALL
	
	SELECT @NotebookId
     , 'HasActivatedProfile' AS 'Field'
	 , CASE WHEN COUNT(*) >= 1 THEN 1 ELSE 0 END
	FROM SRV16.RabotaUA2.dbo.OrderDetail OD
	 JOIN SRV16.RabotaUA2.dbo.Orders O ON OD.OrderID = O.ID
	WHERE O.NotebookID = @NotebookID
	 AND OD.ServiceID IN (25,26)
	 AND @TodayDate BETWEEN OD.ActivationStartDate AND OD.ActivationEndDate;

	RETURN
END
