CREATE TABLE [dbo].[TargetsMonthByWorkExperience] (
    [WorkExperienceFullMonths] SMALLINT        NOT NULL,
    [ContactsPerDay]           SMALLINT        NOT NULL,
    [PaidCompaniesNum]         INT             NOT NULL,
    [FinancePlanMonth]         DECIMAL (16, 2) NOT NULL,
    [MeetingsNumMonth]         INT             NOT NULL,
    [RecognizedRevenueMonth]   DECIMAL (16, 2) NOT NULL,
    [UnqVacancyWeightMonth]    DECIMAL (3, 2)  NOT NULL,
    CONSTRAINT [PK_TargetsMonthByWorkExperience] PRIMARY KEY CLUSTERED ([WorkExperienceFullMonths] ASC)
);

