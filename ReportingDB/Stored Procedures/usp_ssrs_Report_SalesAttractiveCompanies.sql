
-- =============================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-04-14
-- Description:	Процедура возвращает список компаний, которые подпадают под одно из условий
--				- изменялся рекомендованный канал продаж в течении последнего месяца
--				- есть регистрация на ворке с признаком "Бизнес-размещение"
--				- закончились бесплатно начисленные публикации
--				- хотя бы раз на протяжении последних 3-х дней исчерпывали лимит на открытие контактов в CVDB
-- =============================================================================================================

CREATE PROCEDURE [dbo].[usp_ssrs_Report_SalesAttractiveCompanies] 
	@RecomendedChannel NVARCHAR(20),
	@IsBusiness NVARCHAR(20),
	@IsAllFreeTicketsSpent NVARCHAR(20),
	@IsDailyLimitSpent NVARCHAR(20)

AS

BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON;

	DECLARE @Day INT = dbo.fnDayByDate(GETDATE());
	DECLARE @MonthAgo DATETIME = dbo.fnGetDatePart(DATEADD(MONTH, -1, GETDATE()));
	DECLARE @3DaysAgo DATETIME = dbo.fnGetDatePart(DATEADD(DAY, -3, GETDATE()));

	WITH Notebooks_ChangedRecommendedChannel AS
	-- списко блокнотов, у которых изменялся рекомендованный канал продаж в течении последнего месяца
	 (
	SELECT DISTINCT SCR.NotebookID, 1 AS IsChangedSalesChannel
	FROM SRV16.RabotaUA2.dbo.NotebookCompany_SalesChannel_Recommended_History SCR
	 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC ON SCR.NotebookID = NC.NotebookID
	WHERE SCR.AddDate >= @MonthAgo 
	 AND SCR.SalesChannel = 2
	 AND NC.SalesChannel_Recommended = 2
	 ) 
	 , Notebooks_HasBusinessPlacement AS
	-- список блокнотов, у которых есть регистрация на ворке с признаком "Бизнес-размещение"
	 (
	SELECT DISTINCT NotebookID, 1 AS IsBusiness 
	FROM SRV16.RabotaUA2.dbo.SpiderCompany
	WHERE Source = 1 AND IsBusiness = 1
	 )
	 , Notebooks_AllFreeTicketsSpent AS
	-- список блокнотов, у которых закончились бесплатно начисленные публикации
	 (
	SELECT DISTINCT NRT.NotebookID, 1 AS IsAllFreeTicketsSpent
	FROM SRV16.RabotaUA2.dbo.NotebookRegionalTicket NRT
	 JOIN SRV16.RabotaUA2.dbo.RegionalTicketPayment RTP ON NRT.PayId = RTP.Id
	WHERE NRT.PackageId = 18 AND RTP.TicketPaymentTypeID = 6
	 AND @Day BETWEEN NRT.DateStart AND NRT.DateValid
	 AND NRT.TicketRestCount <= 0
	 )
	 , Notebooks_DailyLimitSpent AS
	-- список блокнотов, которые хотя бы раз на протяжении последних 3-х дней исчерпывали лимит на открытие контактов в CVDB
	 (
	SELECT DISTINCT DVR.EmployerNotebookID AS NotebookID, 1 AS IsDailyLimitSpent
	FROM SRV16.RabotaUA2.dbo.DailyViewedResume DVR
	WHERE DVR.ViewDate >= @3DaysAgo
	AND DVR.IsTemporalAccess = 0
	GROUP BY DVR.EmployerNotebookID, DVR.ViewDate 
	HAVING COUNT(*) >= 5
	 )

	-- результирующий набор для отчета
	SELECT NC.NotebookID, NC.Name AS CompanyName, M.Name AS ManagerName
	 , ISNULL(NCRC.IsChangedSalesChannel, 0) AS IsChangedSalesChannel
	 , ISNULL(NBP.IsBusiness, 0) AS IsBusiness
	 , ISNULL(NFT.IsAllFreeTicketsSpent,0) AS IsAllFreeTicketsSpent
	 , ISNULL(NDLS.IsDailyLimitSpent, 0) AS IsDailyLimitSpent
	 , ISNULL(NCRC.IsChangedSalesChannel, 0) + ISNULL(NBP.IsBusiness, 0) + ISNULL(NFT.IsAllFreeTicketsSpent,0) + ISNULL(NDLS.IsDailyLimitSpent, 0) AS Rating 
		-- Rating используем для сортировке компаний по привлекательности в отчете
	FROM SRV16.RabotaUA2.dbo.NotebookCompany NC
	 JOIN SRV16.RabotaUA2.dbo.Manager M ON NC.ManagerID = M.Id
	 LEFT JOIN Notebooks_ChangedRecommendedChannel NCRC ON NC.NotebookID = NCRC.NotebookID
	 LEFT JOIN Notebooks_HasBusinessPlacement NBP ON NC.NotebookID = NBP.NotebookId
	 LEFT JOIN Notebooks_AllFreeTicketsSpent NFT ON NC.NotebookID = NFT.NotebookID
	 LEFT JOIN Notebooks_DailyLimitSpent NDLS ON NC.NotebookID = NDLS.NotebookID
	WHERE M.IsLoyaltyGroup | M.IsTatarovaGroup = 1
	 AND ISNULL(NCRC.IsChangedSalesChannel, 0) | ISNULL(NBP.IsBusiness, 0) | ISNULL(NFT.IsAllFreeTicketsSpent,0) | ISNULL(NDLS.IsDailyLimitSpent, 0) = 1
	 AND ISNULL(NCRC.IsChangedSalesChannel, 0) IN (SELECT Value FROM dbo.udf_SplitString(@RecomendedChannel, ','))
	 AND ISNULL(NBP.IsBusiness, 0) IN (SELECT Value FROM dbo.udf_SplitString(@IsBusiness, ','))
	 AND ISNULL(NFT.IsAllFreeTicketsSpent,0) IN (SELECT Value FROM dbo.udf_SplitString(@IsAllFreeTicketsSpent,','))
	 AND ISNULL(NDLS.IsDailyLimitSpent, 0) IN (SELECT Value FROM dbo.udf_SplitString(@IsDailyLimitSpent,','));

END;