CREATE AGGREGATE [dbo].[Median](@number FLOAT (53))
    RETURNS FLOAT (53)
    EXTERNAL NAME [Median].[Median];

