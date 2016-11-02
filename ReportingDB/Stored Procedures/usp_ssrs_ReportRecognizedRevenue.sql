
/**************************************************************************************************
 MODIFIED BY:	michael <michael@rabota.ua>
 MODIFIED ON:	2016-02-03
 COMMENTS	:	Добавлен параметр @ManagerIDs NVARCHAR(2000) - список Id менеджеров с запятой в 
				качестве разделителя.
				По умолчанию NULL

				Добавляем IF
				Если @ManagerIDs IS NULL, считаем "потребленный сервис" по таблице 
				FactRecognizedRevenue (общие суммы потребленного сервиса).
				Если @ManagerIDs IS NOT NULL или = '0', то считаем по таблице 
				FactRecognizedRevenueNotebook (потребленный сервис в разрезе "блокнотов") 
				только по тем NotebookID, которые закреплены за  @ManagerIDs

**************************************************************************************************
 CREATED BY	:	michael <michael@rabota.ua>
 CREATED ON	:	
 COMMENTS	:	Процедура возвращает сумму "потребленного сервиса" (FactRecognizedRevenue)
				в разрезе календарных дат (DimDate) и типов сервиса (DimService). 
				
				Параметры
				@StartDate - начальная дата, @EndDate - конечная дата
***************************************************************************************************/

CREATE PROCEDURE [dbo].[usp_ssrs_ReportRecognizedRevenue]
	@StartDate DATETIME, 
	@EndDate DATETIME,
	@ManagerIDs NVARCHAR(2000) = NULL

AS

IF @ManagerIDs IS NULL OR @ManagerIDs = '0'

	BEGIN

		SELECT 
		   DS.Service_key
		 , DS.ServiceName
		 , DS.ServiceGroup
		 , DD.FullDate
		 , DD.YearNum
		 , DD.MonthNum
		 , DD.MonthNameRus
		 , DD.MonthNameEng
		 , DD.WeekNum
		 , DD.WeekName
		 , FRR.RecognizedRevenue
		FROM Reporting.dbo.FactRecognizedRevenue FRR
		 JOIN Reporting.dbo.DimDate DD ON FRR.Date_key = DD.Date_key
		 JOIN Reporting.dbo.DimService DS ON FRR.Service_key = DS.Service_key
		WHERE DD.FullDate BETWEEN @StartDate AND @EndDate;

	END

ELSE
	
	BEGIN

		SELECT 
		   DS.Service_key
		 , DS.ServiceName
		 , DS.ServiceGroup
		 , DD.FullDate
		 , DD.YearNum
		 , DD.MonthNum
		 , DD.MonthNameRus
		 , DD.MonthNameEng
		 , DD.WeekNum
		 , DD.WeekName
		 , FRRN.RecognizedRevenue
		FROM dbo.FactRecognizedRevenueNotebook FRRN
		 JOIN Reporting.dbo.DimDate DD ON FRRN.Date_key = DD.Date_key
		 JOIN Reporting.dbo.DimService DS ON FRRN.Service_key = DS.Service_key
		 JOIN Analytics.dbo.NotebookCompany NC ON FRRN.NotebookID = NC.NotebookID
		WHERE DD.FullDate BETWEEN @StartDate AND @EndDate
		 AND NC.ManagerId IN (SELECT Value FROM dbo.udf_SplitString(@ManagerIDs, ','));
		 
	END
