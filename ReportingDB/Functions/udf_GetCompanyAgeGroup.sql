CREATE FUNCTION [dbo].[udf_GetCompanyAgeGroup] 
 (@FirstPubDate DATETIME)
 
 RETURNS VARCHAR(20)

 AS

 BEGIN 

	DECLARE @AgeGroup VARCHAR(20)
	
	SELECT @AgeGroup = 
	 CASE 
	  WHEN DATEDIFF(MONTH, @FirstPubDate, GETDATE()) < 1 THEN 'Ясли'
	  WHEN DATEDIFF(MONTH, @FirstPubDate, GETDATE()) BETWEEN 1 AND 3 THEN 'Младшая группа'
	  WHEN DATEDIFF(MONTH, @FirstPubDate, GETDATE()) BETWEEN 4 AND 6 THEN 'Подростки'
	  WHEN DATEDIFF(MONTH, @FirstPubDate, GETDATE()) >= 7 THEN 'Взрослые'
	  ELSE 'Эмбрионы'
	 END

	RETURN(@AgeGroup);

END