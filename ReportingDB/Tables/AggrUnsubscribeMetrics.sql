CREATE TABLE [dbo].[AggrUnsubscribeMetrics] (
    [FullDate]                  DATE NOT NULL,
    [IsFromApply]               INT  NULL,
    [IsManual]                  INT  NULL,
    [IsSend_Admin4_SeekerType1] INT  NULL,
    [IsSend_Admin4_SeekerType2] INT  NULL,
    [IsSend_Admin4_SeekerType3] INT  NULL,
    [IsSend_Admin4_SeekerType4] INT  NULL,
    CONSTRAINT [PK_AggrUnsubscribeMetrics] PRIMARY KEY CLUSTERED ([FullDate] ASC)
);

