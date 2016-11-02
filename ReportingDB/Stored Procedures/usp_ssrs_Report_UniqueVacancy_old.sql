
CREATE PROCEDURE [dbo].[usp_ssrs_Report_UniqueVacancy_old]

AS

SELECT Website, DepartmentName, ManagerName, VacancyDiffGroup, VacancyCount
FROM 
	(SELECT DC.DepartmentName, DC.ManagerName, DC.VacancyDiffGroup
	 , CASE 
	    WHEN DC.VacancyDiffGroup = 'R = W = 0' THEN 0
	    WHEN DC.VacancyDiffGroup = '0 = R < W' THEN 0
		ELSE DC.UnqVacancyNum 
	   END AS 'rabota.ua'
	 , CASE 
	    WHEN DC.VacancyDiffGroup = 'R = W = 0' THEN 0
	    WHEN DC.VacancyDiffGroup = 'R > W = 0' THEN 0
		ELSE DC.UnqWorkVacancyNum 
	   END AS 'work.ua'
	 , CASE 
	    WHEN DC.VacancyDiffGroup = 'R = W = 0' THEN 0
	    WHEN DC.VacancyDiffGroup = '0 = R < W' THEN 0
		ELSE DC.UnqVacancyNum 
	   END
	    +
	   CASE 
	    WHEN DC.VacancyDiffGroup = 'R = W = 0' THEN 0
	    WHEN DC.VacancyDiffGroup = 'R > W = 0' THEN 0
		ELSE DC.UnqWorkVacancyNum 
	   END AS 'Total'
	FROM Reporting.dbo.DimCompany DC
	WHERE DC.WorkConnectionGroup = 'Привязанные компании'
	 AND (DC.UnqVacancyNum > 0 OR DC.UnqWorkVacancyNum > 0)
	 AND DC.VacancyDiffGroup <> 'R = W = 0') p
UNPIVOT 
 (VacancyCount FOR Website IN ([rabota.ua],[work.ua],[Total])) AS unpvt;
;
