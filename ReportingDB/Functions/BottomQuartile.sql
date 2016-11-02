CREATE AGGREGATE [dbo].[BottomQuartile](@number FLOAT (53))
    RETURNS FLOAT (53)
    EXTERNAL NAME [BottomQuartile].[BottomQuartile];

