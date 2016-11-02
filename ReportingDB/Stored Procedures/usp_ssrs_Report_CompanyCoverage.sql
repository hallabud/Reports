
--exec usp_ssrs_Report_CompanyCoverage '2016-08-01', '2016-09-01', '173'
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-05-19
-- Description:	Процедура возвращает список компаний со следующими полями:
--				- Айди блокнота
--				- Название компании
--				- Менеджер
--				- Факт наличия действия менеджера по данной компании в админ8
--				- Факт наличия активности (вакансии на работа или ворк) в течении отчетного периода
-- ======================================================================================================

CREATE PROCEDURE [dbo].[usp_ssrs_Report_CompanyCoverage]
	(@StartDate DATETIME,
	 @EndDate DATETIME,
	 @ManagerIDs VARCHAR(1000))

AS

BEGIN

	SELECT NC.NotebookId, NC.Name AS CompanyName, M.Name AS Manager
	 , CASE WHEN EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.CRM_Action A WHERE A.NotebookID = NC.NotebookID AND StateID = 2 
	                     AND A.TypeID NOT IN (6,8,9)   -- BI-21
	                     AND MMB.Email = A.Responsible -- BI-21
	                	 AND A.CompleteDate BETWEEN @StartDate --AND @EndDate 
	                	 AND DATEADD(DAY, 1, @EndDate) -- BI-21
	                                           
	 ) THEN 'С действием' ELSE 'Без действия' END AS ActionExistsGroup
	 , CASE WHEN EXISTS (SELECT * 
						 FROM Reporting.dbo.FactCompanyStatuses FCS
						  JOIN Reporting.dbo.DimCompany DC ON FCS.Company_key = DC.Company_key
						  JOIN Reporting.dbo.DimDate DD ON FCS.Date_key = DD.Date_key
						 WHERE DC.NotebookId = NC.NotebookId
						  AND DD.FullDate BETWEEN @StartDate AND @EndDate
						  AND (FCS.VacancyNum > 0 OR FCS.WorkVacancyNum > 0)) THEN 'Активная' ELSE 'Неактивная' END AS ActivityExistsGroup
	FROM  SRV16.RabotaUA2.dbo.NotebookCompany NC
	 JOIN SRV16.RabotaUA2.dbo.Manager M ON NC.ManagerID = M.ID
	 JOIN SRV16.RabotaUA2.dbo.aspnet_Membership MMB ON M.aspnet_UserUIN = MMB.UserID -- BI-21
	WHERE NOT EXISTS (SELECT * FROM Analytics.dbo.NotebookCompanyMerged NCM WHERE NCM.SourceNotebookID = NC.NotebookID)
	 AND ISNULL(NC.IsNetworkCompany,0) = 0
	 AND NC.ManagerId IN (SELECT Value FROM dbo.udf_SplitString (@ManagerIDs,','))

END


