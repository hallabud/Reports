CREATE TABLE [dbo].[AggrCVDBMetrics] (
    [FullDate]                               DATE NOT NULL,
    [ResumeViewedCount]                      INT  NULL,
    [ResumeViewedByCompanyCount]             INT  NULL,
    [ContactsOpenedCount]                    INT  NULL,
    [PageTimeAvg]                            INT  NULL,
    [CompanyFree_HasResumeViews]             INT  NULL,
    [CompanyFree_ResumeViewedCount]          INT  NULL,
    [CompanyFree_HasFiveOpenedContacts]      INT  NULL,
    [CompanyFree_HasFiveOpenedContacts_Week] INT  NULL,
    [CompanyPaidCount]                       INT  NULL,
    [CompanyPaidCount_Unlim]                 INT  NULL,
    [Company_HasOpenedOneContact]            INT  NULL,
    CONSTRAINT [PK_AggrCVDBMetrics] PRIMARY KEY CLUSTERED ([FullDate] ASC)
);

