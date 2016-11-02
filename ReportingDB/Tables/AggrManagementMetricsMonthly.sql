CREATE TABLE [dbo].[AggrManagementMetricsMonthly] (
    [YearNum]                                INT             NOT NULL,
    [MonthNum]                               TINYINT         NOT NULL,
    [MonthName]                              VARCHAR (50)    NOT NULL,
    [ResponsesNum]                           INT             NULL,
    [ResponsesNum_Viewed]                    INT             NULL,
    [SubscribeCompetitor_EmailCount]         INT             NULL,
    [TotalSales_From1C]                      DECIMAL (18, 2) NULL,
    [EmailsAcquired]                         INT             NULL,
    [EmailsAcquired_HasCvPublished]          INT             NULL,
    [EmailsAcquired_HasCvPublishedOrApplied] INT             NULL,
    CONSTRAINT [PK_AggrManagementMetricsMonthly] PRIMARY KEY CLUSTERED ([YearNum] ASC, [MonthNum] ASC, [MonthName] ASC)
);

