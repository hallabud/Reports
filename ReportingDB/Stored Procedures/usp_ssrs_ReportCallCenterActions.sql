
CREATE PROCEDURE [dbo].[usp_ssrs_ReportCallCenterActions]
 (@StartDate DATETIME, @EndDate DATETIME)

AS

--DECLARE @StartDate DATETIME; SET @StartDate = '2013-09-30';
--DECLARE @EndDate DATETIME; SET @EndDate = '2013-10-06';

DECLARE @Responsible TABLE (Responsible VARCHAR(255));

INSERT INTO @Responsible VALUES ('ViktoriyaK@rabota.ua');
INSERT INTO @Responsible VALUES ('KristinaB@rabota.ua');
INSERT INTO @Responsible VALUES ('ElenaS@rabota.ua');
INSERT INTO @Responsible VALUES ('IvanO@rabota.ua');
INSERT INTO @Responsible VALUES ('MarinaS@rabota.ua');
INSERT INTO @Responsible VALUES ('ViktorB@rabota.ua');
INSERT INTO @Responsible VALUES ('JuliyaK@rabota.ua');
INSERT INTO @Responsible VALUES ('JuliyaO@rabota.ua');


SELECT 
   D.FullDate
 , R.Responsible
 , 'Привлечение' AS ProgramName
-- выполненные действия в отчетную дату:
-- дата выполнения действия = отчетная дата
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
	 AND D.FullDate = dbo.fnGetDatePart(A.CompleteDate)
     AND A.ProgramID = 2) AS ActionsDoneNum
-- запланированные действия по состоянию на отчетную дату:
-- отчетная дата >= дата создания действия
-- отчетная дата < дата планового выполнения
-- отчетная дата < дата фактического выполнения ИЛИ Дата фактического выполнения IS NULL
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
	 AND D.FullDate >= dbo.fnGetDatePart(A.AddDate)
     AND D.FullDate <= A.ExecutionDate
     AND (D.FullDate < dbo.fnGetDatePart(A.CompleteDate) OR A.CompleteDate IS NULL)
     AND A.ProgramID = 2) AS ActionsPlanedNum
-- просроченные действия по состоянию на отчетную дату:
-- дата фактического выполнения > дата планового выполнения
-- отчетная дата > дата создания действия
-- отчетная дата > дата планового ввыполнения
-- отчетная дата <= дата фактического выполнения ИЛИ Дата фактического выполнения IS NULL
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
     AND dbo.fnGetDatePart(A.CompleteDate) > A.ExecutionDate
	 AND D.FullDate > dbo.fnGetDatePart(A.AddDate)
	 AND D.FullDate > A.ExecutionDate
	 AND (D.FullDate <= dbo.fnGetDatePart(A.CompleteDate) OR A.CompleteDate IS NULL)
     AND A.ProgramID = 2) AS ActionsDelayedNum
FROM Reporting.dbo.DimDate D
 CROSS JOIN @Responsible R
WHERE D.FullDate BETWEEN @StartDate AND @EndDate

UNION ALL

SELECT 
   D.FullDate
 , R.Responsible
 , 'Возвращение' AS ProgramName
-- выполненные действия в отчетную дату:
-- дата выполнения действия = отчетная дата
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
	 AND D.FullDate = dbo.fnGetDatePart(A.CompleteDate)
     AND A.ProgramID = 3) AS ActionsDoneNum
-- запланированные действия по состоянию на отчетную дату:
-- отчетная дата >= дата создания действия
-- отчетная дата < дата планового выполнения
-- отчетная дата < дата фактического выполнения ИЛИ Дата фактического выполнения IS NULL
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
	 AND D.FullDate >= dbo.fnGetDatePart(A.AddDate)
     AND D.FullDate <= A.ExecutionDate
     AND (D.FullDate < dbo.fnGetDatePart(A.CompleteDate) OR A.CompleteDate IS NULL)
     AND A.ProgramID = 3) AS ActionsPlanedNum
-- просроченные действия по состоянию на отчетную дату:
-- дата фактического выполнения > дата планового выполнения
-- отчетная дата > дата создания действия
-- отчетная дата > дата планового ввыполнения
-- отчетная дата <= дата фактического выполнения ИЛИ Дата фактического выполнения IS NULL
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
     AND dbo.fnGetDatePart(A.CompleteDate) > A.ExecutionDate
	 AND D.FullDate > dbo.fnGetDatePart(A.AddDate)
	 AND D.FullDate > A.ExecutionDate
	 AND (D.FullDate <= dbo.fnGetDatePart(A.CompleteDate) OR A.CompleteDate IS NULL)
     AND A.ProgramID = 3) AS ActionsDelayedNum
FROM Reporting.dbo.DimDate D
 CROSS JOIN @Responsible R
WHERE D.FullDate BETWEEN @StartDate AND @EndDate

UNION ALL

SELECT 
   D.FullDate
 , R.Responsible
 , 'Конвертация' AS ProgramName
-- выполненные действия в отчетную дату:
-- дата выполнения действия = отчетная дата
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
	 AND D.FullDate = dbo.fnGetDatePart(A.CompleteDate)
     AND A.ProgramID = 4) AS ActionsDoneNum
-- запланированные действия по состоянию на отчетную дату:
-- отчетная дата >= дата создания действия
-- отчетная дата < дата планового выполнения
-- отчетная дата < дата фактического выполнения ИЛИ Дата фактического выполнения IS NULL
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
	 AND D.FullDate >= dbo.fnGetDatePart(A.AddDate)
     AND D.FullDate <= A.ExecutionDate
     AND (D.FullDate < dbo.fnGetDatePart(A.CompleteDate) OR A.CompleteDate IS NULL)
     AND A.ProgramID = 4) AS ActionsPlanedNum
-- просроченные действия по состоянию на отчетную дату:
-- дата фактического выполнения > дата планового выполнения
-- отчетная дата > дата создания действия
-- отчетная дата > дата планового ввыполнения
-- отчетная дата <= дата фактического выполнения ИЛИ Дата фактического выполнения IS NULL
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
     AND dbo.fnGetDatePart(A.CompleteDate) > A.ExecutionDate
	 AND D.FullDate > dbo.fnGetDatePart(A.AddDate)
	 AND D.FullDate > A.ExecutionDate
	 AND (D.FullDate <= dbo.fnGetDatePart(A.CompleteDate) OR A.CompleteDate IS NULL)
     AND A.ProgramID = 4) AS ActionsDelayedNum
FROM Reporting.dbo.DimDate D
 CROSS JOIN @Responsible R
WHERE D.FullDate BETWEEN @StartDate AND @EndDate

UNION ALL

SELECT 
   D.FullDate
 , R.Responsible
 , 'Программа не указана' AS ProgramName
-- выполненные действия в отчетную дату:
-- дата выполнения действия = отчетная дата
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
	 AND D.FullDate = dbo.fnGetDatePart(A.CompleteDate)
     AND A.ProgramID = 0) AS ActionsDoneNum
-- запланированные действия по состоянию на отчетную дату:
-- отчетная дата >= дата создания действия
-- отчетная дата < дата планового выполнения
-- отчетная дата < дата фактического выполнения ИЛИ Дата фактического выполнения IS NULL
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
	 AND D.FullDate >= dbo.fnGetDatePart(A.AddDate)
     AND D.FullDate <= A.ExecutionDate
     AND (D.FullDate < dbo.fnGetDatePart(A.CompleteDate) OR A.CompleteDate IS NULL)
     AND A.ProgramID = 0) AS ActionsPlanedNum
-- просроченные действия по состоянию на отчетную дату:
-- дата фактического выполнения > дата планового выполнения
-- отчетная дата > дата создания действия
-- отчетная дата > дата планового ввыполнения
-- отчетная дата <= дата фактического выполнения ИЛИ Дата фактического выполнения IS NULL
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
     AND dbo.fnGetDatePart(A.CompleteDate) > A.ExecutionDate
	 AND D.FullDate > dbo.fnGetDatePart(A.AddDate)
	 AND D.FullDate > A.ExecutionDate
	 AND (D.FullDate <= dbo.fnGetDatePart(A.CompleteDate) OR A.CompleteDate IS NULL)
     AND A.ProgramID = 0) AS ActionsDelayedNum
FROM Reporting.dbo.DimDate D
 CROSS JOIN @Responsible R
WHERE D.FullDate BETWEEN @StartDate AND @EndDate

UNION ALL

SELECT 
   D.FullDate
 , R.Responsible
 , 'Satisfaction research' AS ProgramName
-- выполненные действия в отчетную дату:
-- дата выполнения действия = отчетная дата
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
	 AND D.FullDate = dbo.fnGetDatePart(A.CompleteDate)
     AND A.ProgramID = 10) AS ActionsDoneNum
-- запланированные действия по состоянию на отчетную дату:
-- отчетная дата >= дата создания действия
-- отчетная дата < дата планового выполнения
-- отчетная дата < дата фактического выполнения ИЛИ Дата фактического выполнения IS NULL
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
	 AND D.FullDate >= dbo.fnGetDatePart(A.AddDate)
     AND D.FullDate <= A.ExecutionDate
     AND (D.FullDate < dbo.fnGetDatePart(A.CompleteDate) OR A.CompleteDate IS NULL)
     AND A.ProgramID = 10) AS ActionsPlanedNum
-- просроченные действия по состоянию на отчетную дату:
-- дата фактического выполнения > дата планового выполнения
-- отчетная дата > дата создания действия
-- отчетная дата > дата планового ввыполнения
-- отчетная дата <= дата фактического выполнения ИЛИ Дата фактического выполнения IS NULL
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
     AND dbo.fnGetDatePart(A.CompleteDate) > A.ExecutionDate
	 AND D.FullDate > dbo.fnGetDatePart(A.AddDate)
	 AND D.FullDate > A.ExecutionDate
	 AND (D.FullDate <= dbo.fnGetDatePart(A.CompleteDate) OR A.CompleteDate IS NULL)
     AND A.ProgramID = 10) AS ActionsDelayedNum
FROM Reporting.dbo.DimDate D
 CROSS JOIN @Responsible R
WHERE D.FullDate BETWEEN @StartDate AND @EndDate

UNION ALL

SELECT 
   D.FullDate
 , R.Responsible
 , 'Акция 5+2 & 10+4' AS ProgramName
-- выполненные действия в отчетную дату:
-- дата выполнения действия = отчетная дата
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
	 AND D.FullDate = dbo.fnGetDatePart(A.CompleteDate)
     AND A.ProgramID = 9) AS ActionsDoneNum
-- запланированные действия по состоянию на отчетную дату:
-- отчетная дата >= дата создания действия
-- отчетная дата < дата планового выполнения
-- отчетная дата < дата фактического выполнения ИЛИ Дата фактического выполнения IS NULL
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
	 AND D.FullDate >= dbo.fnGetDatePart(A.AddDate)
     AND D.FullDate <= A.ExecutionDate
     AND (D.FullDate < dbo.fnGetDatePart(A.CompleteDate) OR A.CompleteDate IS NULL)
     AND A.ProgramID = 9) AS ActionsPlanedNum
-- просроченные действия по состоянию на отчетную дату:
-- дата фактического выполнения > дата планового выполнения
-- отчетная дата > дата создания действия
-- отчетная дата > дата планового ввыполнения
-- отчетная дата <= дата фактического выполнения ИЛИ Дата фактического выполнения IS NULL
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
     AND dbo.fnGetDatePart(A.CompleteDate) > A.ExecutionDate
	 AND D.FullDate > dbo.fnGetDatePart(A.AddDate)
	 AND D.FullDate > A.ExecutionDate
	 AND (D.FullDate <= dbo.fnGetDatePart(A.CompleteDate) OR A.CompleteDate IS NULL)
     AND A.ProgramID = 9) AS ActionsDelayedNum
FROM Reporting.dbo.DimDate D
 CROSS JOIN @Responsible R
WHERE D.FullDate BETWEEN @StartDate AND @EndDate

UNION ALL

SELECT 
   D.FullDate
 , R.Responsible
 , 'Активные 2' AS ProgramName
-- выполненные действия в отчетную дату:
-- дата выполнения действия = отчетная дата
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
	 AND D.FullDate = dbo.fnGetDatePart(A.CompleteDate)
     AND A.ProgramID = 12) AS ActionsDoneNum
-- запланированные действия по состоянию на отчетную дату:
-- отчетная дата >= дата создания действия
-- отчетная дата < дата планового выполнения
-- отчетная дата < дата фактического выполнения ИЛИ Дата фактического выполнения IS NULL
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
	 AND D.FullDate >= dbo.fnGetDatePart(A.AddDate)
     AND D.FullDate <= A.ExecutionDate
     AND (D.FullDate < dbo.fnGetDatePart(A.CompleteDate) OR A.CompleteDate IS NULL)
     AND A.ProgramID = 12) AS ActionsPlanedNum
-- просроченные действия по состоянию на отчетную дату:
-- дата фактического выполнения > дата планового выполнения
-- отчетная дата > дата создания действия
-- отчетная дата > дата планового ввыполнения
-- отчетная дата <= дата фактического выполнения ИЛИ Дата фактического выполнения IS NULL
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
     AND dbo.fnGetDatePart(A.CompleteDate) > A.ExecutionDate
	 AND D.FullDate > dbo.fnGetDatePart(A.AddDate)
	 AND D.FullDate > A.ExecutionDate
	 AND (D.FullDate <= dbo.fnGetDatePart(A.CompleteDate) OR A.CompleteDate IS NULL)
     AND A.ProgramID = 12) AS ActionsDelayedNum
FROM Reporting.dbo.DimDate D
 CROSS JOIN @Responsible R
WHERE D.FullDate BETWEEN @StartDate AND @EndDate

UNION ALL

SELECT 
   D.FullDate
 , R.Responsible
 , 'Увеличение потенциала' AS ProgramName
-- выполненные действия в отчетную дату:
-- дата выполнения действия = отчетная дата
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
	 AND D.FullDate = dbo.fnGetDatePart(A.CompleteDate)
     AND A.ProgramID = 13) AS ActionsDoneNum
-- запланированные действия по состоянию на отчетную дату:
-- отчетная дата >= дата создания действия
-- отчетная дата < дата планового выполнения
-- отчетная дата < дата фактического выполнения ИЛИ Дата фактического выполнения IS NULL
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
	 AND D.FullDate >= dbo.fnGetDatePart(A.AddDate)
     AND D.FullDate <= A.ExecutionDate
     AND (D.FullDate < dbo.fnGetDatePart(A.CompleteDate) OR A.CompleteDate IS NULL)
     AND A.ProgramID = 13) AS ActionsPlanedNum
-- просроченные действия по состоянию на отчетную дату:
-- дата фактического выполнения > дата планового выполнения
-- отчетная дата > дата создания действия
-- отчетная дата > дата планового ввыполнения
-- отчетная дата <= дата фактического выполнения ИЛИ Дата фактического выполнения IS NULL
 , (SELECT COUNT(*) 
	FROM SRV16.RabotaUA2.dbo.CRM_Action A 
	WHERE A.Responsible = R.Responsible 
     AND dbo.fnGetDatePart(A.CompleteDate) > A.ExecutionDate
	 AND D.FullDate > dbo.fnGetDatePart(A.AddDate)
	 AND D.FullDate > A.ExecutionDate
	 AND (D.FullDate <= dbo.fnGetDatePart(A.CompleteDate) OR A.CompleteDate IS NULL)
     AND A.ProgramID = 13) AS ActionsDelayedNum
FROM Reporting.dbo.DimDate D
 CROSS JOIN @Responsible R
WHERE D.FullDate BETWEEN @StartDate AND @EndDate
;