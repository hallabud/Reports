CREATE TABLE [dbo].[FactCompanyStatusesY2013] (
    [Company_key]                INT             NOT NULL,
    [Date_key]                   INT             NOT NULL,
    [Rating]                     TINYINT         NULL,
    [IsMegaChecked]              BIT             NULL,
    [IsPriority2013]             BIT             NULL,
    [HasPaidPublishedVacs]       BIT             NOT NULL,
    [HasPaidPublicationsLeft]    BIT             NOT NULL,
    [HasHotPublishedVacs]        BIT             NOT NULL,
    [HasHotPublicationsLeft]     BIT             NOT NULL,
    [HasCVDBAccess]              BIT             NOT NULL,
    [HasActivatedLogo]           BIT             NOT NULL,
    [HasActivatedProfile]        BIT             NOT NULL,
    [MonthsFromRegDate]          SMALLINT        NOT NULL,
    [PublicationsNum]            SMALLINT        NOT NULL,
    [PublicationsNumLast6Months] SMALLINT        NULL,
    [PublicationsNumLast3Months] SMALLINT        NULL,
    [PublicationsNumLast2Months] SMALLINT        NULL,
    [MonthsNumLast6Months]       TINYINT         NULL,
    [MonthsNumLast3Months]       TINYINT         NULL,
    [MonthsNumLast2Months]       TINYINT         NULL,
    [VacancyNum]                 SMALLINT        NULL,
    [WorkVacancyNum]             SMALLINT        NULL,
    [AvgLast3Month]              DECIMAL (20, 4) NULL,
    [IndexActivity]              SMALLINT        NULL,
    [IndexAttraction]            DECIMAL (6, 4)  NULL,
    [VacancyDiffGroup]           VARCHAR (20)    NULL,
    [FakeVacancyNum]             SMALLINT        NULL,
    [FakeVacancyDiffGroup]       VARCHAR (20)    NULL,
    [UnqVacancyNum]              SMALLINT        NULL,
    [UnqWorkVacancyNum]          SMALLINT        NULL,
    [HasPaidServices]            BIT             NULL,
    [PaymentStatusKey]           TINYINT         NULL,
    CONSTRAINT [PK_FactCompanyStatusesY2013] PRIMARY KEY CLUSTERED ([Date_key] ASC, [Company_key] ASC),
    CHECK ([Date_key]>=(4750) AND [Date_key]<=(5114)),
    CONSTRAINT [FK_FactCompanyStatusesY2013_DimPaymentStatus] FOREIGN KEY ([PaymentStatusKey]) REFERENCES [dbo].[DimPaymentStatus] ([PaymentStatusKey])
);


GO
CREATE NONCLUSTERED INDEX [IX_VacancyDiffGroup]
    ON [dbo].[FactCompanyStatusesY2013]([VacancyDiffGroup] ASC)
    INCLUDE([Company_key], [Date_key], [VacancyNum], [WorkVacancyNum], [UnqWorkVacancyNum]);

