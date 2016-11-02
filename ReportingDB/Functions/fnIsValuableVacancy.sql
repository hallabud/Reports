CREATE FUNCTION [dbo].[fnIsValuableVacancy] (
	@VacancyID INT
)
RETURNS BIT
/**************************************************************************************************
 CREATED BY	:	Andrew Smiyan
 CREATED ON	:	27.12.2012
 COMMENTS	:	Функция определяет, привязана ли вакансия к ценной подрубрике.
***************************************************************************************************/
AS
BEGIN
	IF EXISTS(SELECT * FROM SRV16.RabotaUA2.dbo.Vacancy V WITH (NOLOCK)
					JOIN SRV16.RabotaUA2.dbo.VacancyRubricNEW VR WITH (NOLOCK) ON V.ID = VR.VacancyID
					JOIN SRV16.RabotaUA2.dbo.RubricPriority R ON R.RubricID2 = VR.RubricID2
				WHERE V.ID = @VacancyID AND VR.IsMain = 1 
					AND R.ProfLevel1 BETWEEN 1 AND V.ProfLevelID)
		RETURN 1	

	RETURN 0
END
