CREATE FUNCTION [dbo].[udf_SplitString]
	 (
	@List nvarchar(2000),
	@SplitOn nvarchar(5)
	 )  

 RETURNS @RtnValue table 
	 (
	Id int identity(1,1),
	Value nvarchar(100)
	 ) 
 AS  

BEGIN
	
	WHILE (Charindex(@SplitOn,@List)>0)
	
	BEGIN
	 
	INSERT INTO @RtnValue (value)
	SELECT	Value = ltrim(rtrim(Substring(@List,1,Charindex(@SplitOn,@List)-1))) 
	
	SET	@List = Substring(@List,Charindex(@SplitOn,@List)+len(@SplitOn),len(@List))
	
	END 

INSERT INTO @RtnValue (Value)
SELECT Value = ltrim(rtrim(@List))
Return

END