
CREATE PROCEDURE [dbo].[usp_etl_DimCompany]

AS

DECLARE @TodayDate DATETIME = dbo.fnGetDatePart(GETDATE());
DECLARE @Month1LastDate DATETIME = DATEADD(DAY, - DAY(@TodayDate), @TodayDate);
DECLARE @Month2LastDate DATETIME = DATEADD(DAY, - DAY(DATEADD(MONTH, -1, @TodayDate)), DATEADD(MONTH, -1, @TodayDate));
DECLARE @Month3LastDate DATETIME = DATEADD(DAY, - DAY(DATEADD(MONTH, -2, @TodayDate)), DATEADD(MONTH, -2, @TodayDate));

-- Временная таблица: даты первой публикации у нас
IF OBJECT_ID('tempdb..#FirstPubDates','U') IS NOT NULL DROP TABLE #FirstPubDates;

SELECT NotebookID, MIN(AddDate) AS FirstPubDate
INTO #FirstPubDates
FROM SRV16.RabotaUA2.dbo.NotebookCompany_Spent NCS
GROUP BY NotebookID;

-- Временная таблица: привязанные блокноты на ворке
IF OBJECT_ID('tempdb..#SpiderCompanyNotebook','U') IS NOT NULL DROP TABLE #SpiderCompanyNotebook;

SELECT SC.CompanyId, SC.NotebookId, SC.Name, SC.VacancyCount, AddDate
 , ROW_NUMBER() OVER(PARTITION BY NotebookID ORDER BY VacancyCount DESC) AS RowNum
INTO #SpiderCompanyNotebook
FROM SRV16.RabotaUA2.dbo.SpiderCompany SC WITH (NOLOCK)
WHERE SC.Source = 1 
 AND SC.IsApproved = 1
 AND NotebookId IS NOT NULL;

-- Временная таблица: количество вакансий по состоянию на последние дни последних 3-х месяцев
IF OBJECT_ID('tempdb..#VacancyNum3Months','U') IS NOT NULL DROP TABLE #VacancyNum3Months;

CREATE TABLE #VacancyNum3Months (FullDate DATETIME, NotebookID INT, VacancyNum INT, Source VARCHAR(10));

INSERT INTO #VacancyNum3Months
EXEC usp_etl_GetVacancyNumsLast3Month;

-- Удаляем записи из таблицы FactCompanyStatuses компаний, которые были удалены из продакшн-базы
DELETE FROM dbo.FactCompanyStatuses
FROM dbo.FactCompanyStatuses FCS 
 JOIN dbo.DimCompany DC ON FCS.Company_key = DC.Company_key
WHERE NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompany WITH (NOLOCK) WHERE NotebookId = DC.NotebookId);

-- Удаляем записи из таблицы DimCompany компаний, которые были удалены из продакшн-базы
DELETE FROM DC FROM dbo.DimCompany DC WHERE NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompany WITH (NOLOCK) WHERE NotebookId = DC.NotebookId);

-- Удаляем записи из таблицы FatcCompanyStatuses компаний, которые были слиты в другие блокноты
DELETE FCS
FROM Reporting.dbo.FactCompanyStatuses FCS 
 JOIN Reporting.dbo.DimCompany DC ON FCS.Company_key = DC.Company_key
WHERE EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompanyMerged WITH (NOLOCK) WHERE SourceNotebookId = DC.NotebookId);

-- Удаляем записи из таблицы DimCompany компаний, которые были слиты в другие блокноты
DELETE FROM DC 
FROM Reporting.dbo.DimCompany DC 
WHERE EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompanyMerged WITH (NOLOCK) WHERE SourceNotebookId = DC.NotebookId);

-- Добавляем новые блокноты, которых нет в таблице DimCompany
INSERT INTO dbo.DimCompany (Region_key, NotebookId, CompanyName, RegDate, FirstPubDate, CompanyState, ManagerName, DepartmentName, WorkConnectionGroup, WorkCompanyID, WorkCompanyName, WorkVacancyNum, WorkFirstPubDate, AgeGroup,
							IsAgency, HasWebsite, VacancyNum)
SELECT 
   DR.Region_key
 , NC.NotebookId
 , NC.Name
 , NC.AddDate
 , FPD.FirstPubDate
 , NS.Name
 , M.Name
 , D.Name
 , CASE 
    WHEN SCN.CompanyID IS NOT NULL THEN 'Привязанные компании'
	ELSE 'Компании на rabota.ua без привязки к work.ua'
   END
 , SCN.CompanyId
 , SCN.Name
 , SCN.VacancyCount
 , SCN.AddDate
 , dbo.udf_GetCompanyAgeGroup(FPD.FirstPubDate)
 , ISNULL(NC.IsAgency,0)
 , CASE WHEN NC.ContactURL IS NULL THEN 0 ELSE 1 END
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.VacancyPublished VP WITH (NOLOCK)
	 JOIN SRV16.RabotaUA2.dbo.VacancyExtra VE WITH (NOLOCK) ON VP.ID = VE.VacancyID 
	WHERE NC.NotebookId = VP.NotebookID AND VE.IsModerated = 1 AND VE.IsModeratedRubric = 1)
FROM SRV16.RabotaUA2.dbo.NotebookCompany NC WITH (NOLOCK)
 JOIN SRV16.RabotaUA2.dbo.Notebook N WITH (NOLOCK) ON NC.NotebookID = N.ID
 JOIN SRV16.RabotaUA2.dbo.NotebookState NS WITH (NOLOCK) ON N.NotebookStateID = NS.ID
 JOIN Reporting.dbo.DimRegion DR ON NC.HeadquarterCityID = DR.AnalyticsDbId
 JOIN SRV16.RabotaUA2.dbo.Manager M WITH (NOLOCK) ON NC.ManagerId = M.Id
 JOIN SRV16.RabotaUA2.dbo.Departments D WITH (NOLOCK) ON M.DepartmentId = D.Id
 LEFT JOIN #SpiderCompanyNotebook SCN ON NC.NotebookId = SCN.NotebookID AND SCN.RowNum = 1
 LEFT JOIN #FirstPubDates FPD ON NC.NotebookId = FPD.NotebookID
WHERE NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompanyMerged NCM WITH (NOLOCK) WHERE NCM.SourceNotebookId = NC.NotebookId)
 AND NOT EXISTS (SELECT * FROM Reporting.dbo.DimCompany DC WHERE DC.NotebookId = NC.NotebookId);

-- Обновляем значения названия компании, текущего статуса компании, статус наличия вебсайта, и признака является ли компания агентством
UPDATE DC
SET CompanyName = NC.Name, CompanyState = NS.Name, IsAgency = ISNULL(NC.IsAgency,0), HasWebsite = CASE WHEN NC.ContactURL IS NULL THEN 0 ELSE 1 END
FROM dbo.DimCompany DC
 JOIN SRV16.RabotaUA2.dbo.Notebook N WITH (NOLOCK) ON DC.NotebookId = N.ID
 JOIN SRV16.RabotaUA2.dbo.NotebookState NS WITH (NOLOCK) ON N.NotebookStateID = NS.ID
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC WITH (NOLOCK) ON DC.NotebookId = NC.NotebookID

-- Обновляем значения текущего менеджера компании и отдела компании
UPDATE DC
SET ManagerName = M.Name, DepartmentName = D.Name
--SELECT DC.*, M.Name, D.Name
FROM dbo.DimCompany DC
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC WITH (NOLOCK) ON DC.NotebookId = NC.NotebookID
 JOIN SRV16.RabotaUA2.dbo.Manager M WITH (NOLOCK) ON NC.ManagerId = M.Id
 JOIN SRV16.RabotaUA2.dbo.Departments D WITH (NOLOCK) ON M.DepartmentID = D.Id
WHERE M.Name <> DC.ManagerName OR D.Name <> DC.DepartmentName

-- Обновляем адрес электронной почты / логин менеджера
UPDATE DC
SET ManagerEmail = AM.LoweredEmail
FROM dbo.DimCompany DC
 JOIN SRV16.RabotaUA2.dbo.Manager M ON DC.ManagerName = M.Name AND M.DepartmentID <> 7
 JOIN SRV16.RabotaUA2.dbo.aspnet_Membership AM ON M.aspnet_UserUIN = AM.UserId;

 -- Обновляем адрес электронной почты / логин менеджера
 -- для компаний, менеджер которых = 'rabota.ua'
UPDATE dbo.DimCompany
SET ManagerEmail = 'info@rabota.ua'
WHERE ManagerName = 'rabota.ua';

-- Обновляем данные по привязанным компаниям
UPDATE DC
 SET WorkConnectionGroup = CASE 
							WHEN SCN.CompanyID IS NOT NULL THEN 'Привязанные компании'
							ELSE 'Компании на rabota.ua без привязки к work.ua'
						   END
 , WorkCompanyID = SCN.CompanyId
 , WorkCompanyName = SCN.Name
 , WorkVacancyNum = SCN.VacancyCount
 , WorkFirstPubDate = SCN.AddDate
FROM dbo.DimCompany DC
 LEFT JOIN #SpiderCompanyNotebook SCN ON DC.NotebookId = SCN.NotebookID AND SCN.RowNum = 1;

-- Обновляем даты первой публикации вакансий
UPDATE DC
SET FirstPubDate = FPD.FirstPubDate
FROM dbo.DimCompany DC
 LEFT JOIN #FirstPubDates FPD ON DC.NotebookId = FPD.NotebookID;

-- Обновляем возрастные группы компаний
UPDATE DC
SET DC.AgeGroup = dbo.udf_GetCompanyAgeGroup(DC.FirstPubDate)
FROM dbo.DimCompany DC

-- Обновляем значения количества вакансий по состоянию на последние дни последних 3-х месяцев
UPDATE DC
SET	
   VacancyNumMonth1 = ISNULL((SELECT VacancyNum FROM #VacancyNum3Months WHERE NotebookID = DC.NotebookID AND Source = 'rabota.ua' AND FullDate = @Month1LastDate),0)
 , VacancyNumMonth2 = ISNULL((SELECT VacancyNum FROM #VacancyNum3Months WHERE NotebookID = DC.NotebookID AND Source = 'rabota.ua' AND FullDate = @Month2LastDate),0)
 , VacancyNumMonth3 = ISNULL((SELECT VacancyNum FROM #VacancyNum3Months WHERE NotebookID = DC.NotebookID AND Source = 'rabota.ua' AND FullDate = @Month3LastDate),0)
 , WorkVacancyNumMonth1 = ISNULL((SELECT VacancyNum FROM #VacancyNum3Months WHERE NotebookID = DC.WorkCompanyID AND Source = 'work.ua' AND FullDate = @Month1LastDate),0)
 , WorkVacancyNumMonth2 = ISNULL((SELECT VacancyNum FROM #VacancyNum3Months WHERE NotebookID = DC.WorkCompanyID AND Source = 'work.ua' AND FullDate = @Month2LastDate),0)
 , WorkVacancyNumMonth3 = ISNULL((SELECT VacancyNum FROM #VacancyNum3Months WHERE NotebookID = DC.WorkCompanyID AND Source = 'work.ua' AND FullDate = @Month3LastDate),0)
FROM dbo.DimCompany DC

-- Обновляем значение среднего кол-ва вакансий за последние 3 мес.
UPDATE DC
SET AvgLast3Month = (dbo.fnGetMaximumOf2Values(DC.VacancyNumMonth1, DC.WorkVacancyNumMonth1) + dbo.fnGetMaximumOf2Values(DC.VacancyNumMonth2, DC.WorkVacancyNumMonth2) + dbo.fnGetMaximumOf2Values(DC.VacancyNumMonth3, DC.WorkVacancyNumMonth3)) / 3
FROM dbo.DimCompany DC;

-- Обновляем значение индекса активности
WITH C AS
 (
SELECT DC.NotebookID, NTILE(10) OVER(ORDER BY AvgLast3Month ASC) AS Grp
FROM dbo.DimCompany DC
WHERE AvgLast3Month > 0
 )
UPDATE DC
SET IndexActivity = ISNULL(C.Grp, 0)
FROM dbo.DimCompany DC
 LEFT JOIN C ON DC.NotebookId = C.NotebookId;

-- Обновляем значение индекса привлекательности
UPDATE DC
SET IndexAttraction = IndexActivity 
					   * CASE 
						  WHEN COALESCE(dbo.fnGetMinimumOf2ValuesDate(RegDate, WorkFirstPubDate), RegDate) >= DATEADD(MONTH, -3, GETDATE()) THEN 0.6
						  WHEN COALESCE(dbo.fnGetMinimumOf2ValuesDate(RegDate, WorkFirstPubDate), RegDate) BETWEEN DATEADD(MONTH, -6, GETDATE()) AND DATEADD(MONTH, -3, GETDATE()) THEN 0.8
						  WHEN COALESCE(dbo.fnGetMinimumOf2ValuesDate(RegDate, WorkFirstPubDate), RegDate) BETWEEN DATEADD(MONTH, -12, GETDATE()) AND DATEADD(MONTH, -6, GETDATE()) THEN 0.9
						  WHEN COALESCE(dbo.fnGetMinimumOf2ValuesDate(RegDate, WorkFirstPubDate), RegDate) < DATEADD(MONTH, -12, GETDATE()) THEN 1
						 END
					   * CASE DC.HasWebsite WHEN 1 THEN 1.0 ELSE 0.7 END
					   * CASE DC.IsAgency WHEN 0 THEN 1.0 ELSE 0.6 END
					   * ISNULL(NIVV.IndexValuableVacancy, 0.55)
					   * CASE 
					      WHEN NC.BranchId = 37 OR (NC.BranchId = 34 AND NC.BranchSubID = 31) OR (NC.BranchSubID IN (59,60,79,82,83,85,86,88,91,92,95,162,184,185,186,187,188,189)) THEN 0.6
						  WHEN NC.Rating = 5 THEN 1.
						  WHEN NC.Rating = 4 THEN 0.8
						  WHEN NC.Rating = 3 THEN 0.6
						  ELSE 0.6
					     END
					   * CASE   
					      WHEN NC.IsLegalPerson = 1 OR (NC.IsLegalPerson = 0 AND NC.IsCorporativeEmail = 1) THEN 1.
						  ELSE 0.6
						 END
FROM dbo.DimCompany DC
 LEFT JOIN dbo.NotebookIndexValuableVacancy NIVV ON DC.NotebookId = NIVV.NotebookId
 JOIN SRV16.RabotaUA2.dbo.NotebookCompany NC WITH (NOLOCK) ON DC.NotebookId = NC.NotebookId

-- Обновляем значение кол-ва опубликованных вакансий

UPDATE DC
SET VacancyNum = (SELECT COUNT(*) 
				  FROM SRV16.RabotaUA2.dbo.VacancyPublished VP WITH (NOLOCK)
				   JOIN SRV16.RabotaUA2.dbo.VacancyExtra VE WITH (NOLOCK) ON VP.ID = VE.VacancyID 
				  WHERE DC.NotebookId = VP.NotebookID AND VE.IsModerated = 1 AND VE.IsModeratedRubric = 1)
FROM dbo.DimCompany DC

-- Обновляем значения принадлежности к группе в зависимости от разницы в вакансиях между нами и ворком
UPDATE DC
SET VacancyDiffGroup = CASE 
						WHEN ISNULL(WorkVacancyNum,0) = 0 AND VacancyNum > ISNULL(WorkVacancyNum,0) THEN 'R > W = 0'
						WHEN ISNULL(WorkVacancyNum,0) > 0 AND VacancyNum > ISNULL(WorkVacancyNum,0) THEN 'R > W > 0'
						WHEN VacancyNum > 0 AND ISNULL(WorkVacancyNum,0) = VacancyNum THEN 'R = W'
						WHEN VacancyNum > 0 AND VacancyNum < ISNULL(WorkVacancyNum,0) THEN '0 < R < W'
						WHEN VacancyNum = 0 AND VacancyNum < ISNULL(WorkVacancyNum,0) THEN '0 = R < W'
						ELSE 'R = W = 0'
					   END
FROM dbo.DimCompany DC

-- Обновляем значения кол-ва уникальных вакансий у нас и на ворке
UPDATE DC
SET UnqVacancyNum = (SELECT COUNT(*) 
					 FROM SRV16.RabotaUA2.dbo.VacancyPublished VP WITH (NOLOCK)
					 WHERE VP.NotebookID = DC.NotebookID 
					  AND NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.SpiderVacancy SV WITH (NOLOCK) WHERE SV.Source = 1 AND SV.IsPublish = 1 AND SV.VacancyID = VP.ID))
 , UnqWorkVacancyNum = (SELECT COUNT(*)
						FROM SRV16.RabotaUA2.dbo.SpiderCompany SC WITH (NOLOCK)
						 JOIN SRV16.RabotaUA2.dbo.SpiderVacancy SV WITH (NOLOCK) ON SV.Source = 1 AND SC.CompanyID = SV.SpiderCompanyID
						WHERE SC.CompanyID = DC.WorkCompanyID
						 AND SC.Source = 1 AND SV.IsPublish = 1 AND SC.IsApproved = 1
						 -- нет привязанной вакансии (поле SC.VacancyID) ИЛИ если есть привязанная НЕ в статусе ("опубликована","приостановленная")
						 AND (
							  SV.VacancyID IS NULL 
								OR (
									SV.VacancyID IS NOT NULL 
										AND NOT EXISTS (SELECT * 
														FROM SRV16.RabotaUA2.dbo.Vacancy V WITH (NOLOCK) 
														WHERE V.ID = SV.VacancyID
														 AND V.State IN (4,6))
										AND NOT EXISTS (SELECT *
														FROM SRV16.RabotaUA2.dbo.Vacancy V WITH (NOLOCK)
														WHERE V.ID = SV.VacancyID
														 AND V.State = 3
														 AND V.StateDate >= DATEADD(DAY, -7, @TodayDate))
								   )
							 )
						 AND NOT EXISTS (SELECT * 
										 FROM SRV16.RabotaUA2.dbo.SpiderVacancy SV1 WITH (NOLOCK) 
										 WHERE SV1.SpiderCompanyID = SV.SpiderCompanyID 
										  AND SV1.SpiderVacancyID <> SV.SpiderVacancyID 
										  AND SV1.CityID = SV.CityID 
										  AND REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(SV1.Name, ' ' , ''), '-', ''), ',', ''), '.', ''), '(', ''), ')', ''), '/', ''), '\', '') 
												= REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(SV.Name, ' ' , ''), '-', ''), ',', ''), '.', ''), '(', ''), ')', ''), '/', ''), '\', '')))
FROM DimCompany DC
WHERE DC.WorkConnectionGroup = 'Привязанные компании'

-- Добавляем значения кол-ва вакансий привязанных компаний на работе.уа и ворке.уа по состоянию на отчетную дату
DECLARE @TodayDateKey INT
SELECT @TodayDateKey = Date_key FROM Reporting.dbo.DimDate WHERE FullDate = dbo.fnGetDatePart(GETDATE());

DECLARE @Date DATETIME;
SET @Date = DATEADD(DAY, -30, GETDATE());

WITH C AS
 (
SELECT 'rabota.ua' AS Website
 , CASE WHEN VP.AddDate < @Date THEN 'Продленная' ELSE 'Новая' END AS PubType
 , COUNT(*) AS VacancyCnt
FROM SRV16.RabotaUA2.dbo.VacancyPublished VP WITH (NOLOCK)
 JOIN Reporting.dbo.DimCompany DC ON VP.NotebookID = DC.NotebookId
WHERE DC.WorkConnectionGroup = 'Привязанные компании'
GROUP BY CASE WHEN VP.AddDate < @Date THEN 'Продленная' ELSE 'Новая' END

UNION ALL

SELECT 'work.ua'
 , CASE WHEN SV.AddDate < @Date THEN 'Продленная' ELSE 'Новая' END AS PubType
 , COUNT(*)
FROM SRV16.RabotaUA2.dbo.SpiderCompany SC WITH (NOLOCK)
 JOIN Reporting.dbo.DimCompany DC ON DC.WorkCompanyID = SC.CompanyID
 JOIN SRV16.RabotaUA2.dbo.SpiderVacancy SV WITH (NOLOCK) ON SV.Source = 1 AND SC.CompanyID = SV.SpiderCompanyID
WHERE SC.Source = 1 AND SV.IsPublish = 1 AND SC.IsApproved = 1
GROUP BY CASE WHEN SV.AddDate < @Date THEN 'Продленная' ELSE 'Новая' END
 )
INSERT INTO Reporting.dbo.LinkedCompaniesVacancyCount
SELECT @TodayDateKey, * 
FROM C

UNION ALL

SELECT 
   @TodayDateKey
 , 'GAP, %'
 , 'Продленная'
 , CAST(100. * ((SELECT VacancyCnt FROM C WHERE PubType = 'Продленная' AND Website = 'rabota.ua') - (SELECT VacancyCnt FROM C WHERE PubType = 'Продленная' AND Website = 'work.ua')) / dbo.fnGetMinimumOf2Values((SELECT VacancyCnt FROM C WHERE PubType = 'Продленная' AND Website = 'rabota.ua'), (SELECT VacancyCnt FROM C WHERE PubType = 'Продленная' AND Website = 'work.ua')) AS INT)

UNION ALL

SELECT 
   @TodayDateKey
 , 'GAP, %'
 , 'Новая'
 , CAST(100. * ((SELECT VacancyCnt FROM C WHERE PubType = 'Новая' AND Website = 'rabota.ua') - (SELECT VacancyCnt FROM C WHERE PubType = 'Новая' AND Website = 'work.ua')) / dbo.fnGetMinimumOf2Values((SELECT VacancyCnt FROM C WHERE PubType = 'Новая' AND Website = 'rabota.ua'), (SELECT VacancyCnt FROM C WHERE PubType = 'Новая' AND Website = 'work.ua')) AS INT)


-- Удаляем временные таблицы
DROP TABLE #SpiderCompanyNotebook;
DROP TABLE #FirstPubDates;
DROP TABLE #VacancyNum3Months;

