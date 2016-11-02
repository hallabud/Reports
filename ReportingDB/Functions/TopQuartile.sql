CREATE AGGREGATE [dbo].[TopQuartile](@number FLOAT (53))
    RETURNS FLOAT (53)
    EXTERNAL NAME [TopQuartile].[TopQuartile];

