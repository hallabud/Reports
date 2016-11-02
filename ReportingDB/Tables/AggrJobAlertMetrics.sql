CREATE TABLE [dbo].[AggrJobAlertMetrics] (
    [FullDate]                            DATE NOT NULL,
    [EmailsSubscribed_NotCompany]         INT  NULL,
    [EmailsSubscribed_Company]            INT  NULL,
    [SubscriptionCount_NotCompany]        INT  NULL,
    [SubscriptionCount_Company]           INT  NULL,
    [EmailsSent_NotCompany]               INT  NULL,
    [EmailsSent_Company]                  INT  NULL,
    [LettersSent_NotCompany]              INT  NULL,
    [LettersSent_Company]                 INT  NULL,
    [EmailsViewedOrSiteViewed_NotCompany] INT  NULL,
    [EmailsViewedOrSiteViewed_Company]    INT  NULL,
    [LetterViewedOrSiteViewed_NotCompany] INT  NULL,
    [LetterViewedOrSiteViewed_Company]    INT  NULL,
    [EmailsSiteViewed_NotCompany]         INT  NULL,
    [EmailsSiteViewed_Company]            INT  NULL,
    [LetterSiteViewed_NotCompany]         INT  NULL,
    [LetterSiteViewed_Company]            INT  NULL,
    [ga_goal13Completions]                INT  NULL,
    [VacancyPoolCount]                    INT  NULL,
    CONSTRAINT [PK_AggrJobAlertMetrics] PRIMARY KEY CLUSTERED ([FullDate] ASC)
);

