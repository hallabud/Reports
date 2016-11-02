CREATE PROCEDURE [dbo].[usp_etl_DimSpiderCompany_Updates]

AS

-- процедура:: проапдейтить поля по ворковским компаниям

-- процедура посчитать кол-во за 3 мес. по непривязанным на ворке
DECLARE @TodayDate DATETIME = dbo.fnGetDatePart(GETDATE());
DECLARE @Month1LastDate DATETIME = DATEADD(DAY, - DAY(@TodayDate), @TodayDate);
DECLARE @Month2LastDate DATETIME = DATEADD(DAY, - DAY(DATEADD(MONTH, -1, @TodayDate)), DATEADD(MONTH, -1, @TodayDate));
DECLARE @Month3LastDate DATETIME = DATEADD(DAY, - DAY(DATEADD(MONTH, -2, @TodayDate)), DATEADD(MONTH, -2, @TodayDate));

DECLARE @Month1LastDateKey INT;
DECLARE @Month2LastDateKey INT;
DECLARE @Month3LastDateKey INT;
SELECT @Month1LastDateKey = Date_key FROM dbo.DimDate WHERE FullDate = @Month1LastDate;
SELECT @Month2LastDateKey = Date_key FROM dbo.DimDate WHERE FullDate = @Month2LastDate;
SELECT @Month3LastDateKey = Date_key FROM dbo.DimDate WHERE FullDate = @Month3LastDate;


UPDATE DSC
SET 
   VacancyNumMonth1 = ISNULL((SELECT VacancyCount FROM dbo.FactSpiderCompanyIndexes FSCI WHERE FSCI.SpiderCompanyID = DSC.SpiderCompanyID AND FSCI.Date_key = @Month1LastDateKey),0)
 , VacancyNumMonth2 = ISNULL((SELECT VacancyCount FROM dbo.FactSpiderCompanyIndexes FSCI WHERE FSCI.SpiderCompanyID = DSC.SpiderCompanyID AND FSCI.Date_key = @Month2LastDateKey),0)
 , VacancyNumMonth3 = ISNULL((SELECT VacancyCount FROM dbo.FactSpiderCompanyIndexes FSCI WHERE FSCI.SpiderCompanyID = DSC.SpiderCompanyID AND FSCI.Date_key = @Month3LastDateKey),0)
FROM dbo.DimSpiderCompany DSC;
 

-- Обновляем значение индекса активности
WITH C AS
 (
SELECT DSC.SpiderCompanyID, NTILE(10) OVER(ORDER BY DSC.AvgLast3Month ASC) AS Grp
FROM dbo.DimSpiderCompany DSC
WHERE DSC.AvgLast3Month > 0
 )
UPDATE DSC
SET IndexActivity = ISNULL(C.Grp, 0)
FROM dbo.DimSpiderCompany DSC
 LEFT JOIN C ON DSC.SpiderCompanyID = C.SpiderCompanyID;


 -- Обновляем значение индекса привлекательности
UPDATE DSC
SET IndexAttraction = IndexActivity 
					   * CASE WHEN CompanyWebsite IS NOT NULL THEN 1 ELSE 0.7 END
					   * CASE IsAgency WHEN 0 THEN 1.0 ELSE 0.6 END
					   * CASE   
					      WHEN IsApproved = 1 THEN 1.
						  ELSE 0.6
						 END
					   * ISNULL(I.IndexValuableVacancy, 0.55)
					   * CASE 
					      WHEN Rating = 5 THEN 1.
						  WHEN Rating = 4 THEN 0.8
						  WHEN Rating = 3 THEN 0.6
						  ELSE 0.6
					     END
					   * CASE
						  WHEN CompanyName LIKE '% [ЧП]П' OR CompanyName LIKE '%Ф[ОЛ]П%' OR CompanyName LIKE '%СПД%' THEN 0.6
						  ELSE 1.
						 END
FROM dbo.DimSpiderCompany DSC
 LEFT JOIN dbo.NotebookIndexValuableVacancy_Work I ON DSC.CompanyID = I.CompanyID