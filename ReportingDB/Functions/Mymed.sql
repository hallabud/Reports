CREATE AGGREGATE [dbo].[Mymed](@number FLOAT (53))
    RETURNS FLOAT (53)
    EXTERNAL NAME [Mymed].[Mymed];

