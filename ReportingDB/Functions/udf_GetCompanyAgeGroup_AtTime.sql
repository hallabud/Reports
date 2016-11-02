CREATE FUNCTION [dbo].[udf_GetCompanyAgeGroup_AtTime] 
 (@FirstPubDate DATETIME,
  @ReportDate DATETIME)
 
 RETURNS VARCHAR(20)

 AS

 BEGIN 

	DECLARE @AgeGroup VARCHAR(20)
	
	SELECT @AgeGroup = 
	 CASE 
	  WHEN DATEDIFF(DAY, @FirstPubDate, @ReportDate) < 30 THEN 'Ясли'
	  WHEN DATEDIFF(DAY, @FirstPubDate, @ReportDate) BETWEEN 30 AND 90 THEN 'Младшая группа'
	  WHEN DATEDIFF(DAY, @FirstPubDate, @ReportDate) BETWEEN 91 AND 180 THEN 'Подростки'
	  WHEN DATEDIFF(DAY, @FirstPubDate, @ReportDate) >= 180 THEN 'Взрослые'
	  ELSE 'Эмбрионы'
	 END

	RETURN(@AgeGroup);

END