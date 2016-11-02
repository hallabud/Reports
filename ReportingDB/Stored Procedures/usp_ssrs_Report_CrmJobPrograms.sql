CREATE PROCEDURE dbo.usp_ssrs_Report_CrmJobPrograms
 (@StartDate DATETIME, @EndDate DATETIME, @JobProgramID SMALLINT)

AS

DECLARE @JobProgramName VARCHAR(50);

SELECT @JobProgramName = Name FROM Analytics.dbo.CRM_JobProgram WHERE ID = @JobProgramID;


-- Общий пул назначенных действий
SELECT @JobProgramName AS JobProgramName, DD.YearNum, DD.MonthNum, DD.MonthNameRus, NL.NotebookID
 , 'Нет контакта - Не звонили' AS 'WasSuccessfulContact'
 , CASE
    WHEN EXISTS (SELECT * 
				 FROM Analytics.dbo.NotebookCompany_Spent NCS
				 WHERE NCS.NotebookID = NL.NotebookId 
				  AND NCS.AddDate BETWEEN DD.FirstMonthDate AND DD.LastMonthDate + 1) THEN 'Есть вакансия'
    ELSE 'Нет вакансии'
   END AS 'HasVacancy'
FROM Analytics.dbo.CRM_JobProgram_NotebookLog NL 
 JOIN Reporting.dbo.DimDate DD ON Analytics.dbo.fnGetDatePart(NL.AddDate) = DD.FullDate
WHERE NL.JobProgramID = @JobProgramID AND NL.IsAssigned = 1
 AND NL.AddDate BETWEEN @StartDate AND @EndDate + 1
 AND NOT EXISTS (SELECT * FROM Analytics.dbo.CRM_Action A WHERE A.NotebookID = NL.NotebookID AND A.JobProgramID = @JobProgramID)

UNION ALL

-- кол-во выполненных действий
SELECT @JobProgramName AS JobProgramName, DD.YearNum, DD.MonthNum, DD.MonthNameRus, A.NotebookID
 , CASE 
    WHEN EXISTS (SELECT * 
	             FROM Analytics.dbo.CRM_Action_QuestionAnswer AQA
				  JOIN Analytics.dbo.CRM_JobProgram_Question_Answer JPQA ON AQA.QuestionID = JPQA.QuestionID AND AQA.PositionID = JPQA.PositionID
				 WHERE AQA.ActionID = A.ID
				  AND A.CompleteDate BETWEEN DD.FirstMonthDate AND DD.LastMonthDate
				  AND JPQA.Name <> 'Недозвон') THEN 'Есть контакт'
	ELSE 'Нет контакта - Недозвон'
   END AS 'WasSuccessfulContact'
 , CASE
    WHEN EXISTS (SELECT * 
				 FROM Analytics.dbo.NotebookCompany_Spent NCS
				 WHERE NCS.NotebookID = A.NotebookId 
				  AND NCS.AddDate BETWEEN DD.FirstMonthDate AND DD.LastMonthDate + 1) THEN 'Есть вакансия'
    ELSE 'Нет вакансии'
   END AS 'HasVacancy'
FROM Analytics.dbo.CRM_Action A 
 JOIN Reporting.dbo.DimDate DD ON Analytics.dbo.fnGetDatePart(A.CompleteDate) = DD.FullDate
WHERE A.JobProgramID = @JobProgramID AND A.StateID = 2
 AND A.CompleteDate BETWEEN @StartDate AND @EndDate + 1;