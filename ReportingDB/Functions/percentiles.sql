CREATE AGGREGATE [dbo].[percentiles](@value FLOAT (53), @percentile SMALLINT, @calcMethod NVARCHAR (4000))
    RETURNS FLOAT (53)
    EXTERNAL NAME [sql.clr.percentiles].[Percentiles];

