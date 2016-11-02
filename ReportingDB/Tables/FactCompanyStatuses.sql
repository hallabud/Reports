CREATE TABLE [dbo].[FactCompanyStatuses] (
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
    CONSTRAINT [PK_FactCompanyStatuses] PRIMARY KEY CLUSTERED ([Date_key] ASC, [Company_key] ASC),
    CONSTRAINT [FK_FactCompanyStatuses_DimPaymentStatus] FOREIGN KEY ([PaymentStatusKey]) REFERENCES [dbo].[DimPaymentStatus] ([PaymentStatusKey])
);


GO
CREATE NONCLUSTERED INDEX [IX_Active2_Megacheked]
    ON [dbo].[FactCompanyStatuses]([IsMegaChecked] ASC, [PublicationsNumLast2Months] ASC, [MonthsNumLast2Months] ASC)
    INCLUDE([HasPaidPublishedVacs], [HasPaidPublicationsLeft], [HasHotPublishedVacs], [HasHotPublicationsLeft], [HasCVDBAccess], [HasActivatedLogo], [HasActivatedProfile]);


GO
ALTER INDEX [IX_Active2_Megacheked]
    ON [dbo].[FactCompanyStatuses] DISABLE;


GO
CREATE NONCLUSTERED INDEX [IX_PuplicationNumLast6Months_WithIncluded]
    ON [dbo].[FactCompanyStatuses]([PublicationsNumLast6Months] ASC)
    INCLUDE([Company_key], [Date_key], [IsMegaChecked], [HasPaidPublishedVacs], [HasPaidPublicationsLeft], [PublicationsNumLast2Months], [MonthsNumLast6Months], [MonthsNumLast3Months], [MonthsNumLast2Months], [HasHotPublishedVacs], [HasHotPublicationsLeft], [HasCVDBAccess], [HasActivatedLogo], [HasActivatedProfile], [PublicationsNumLast3Months]);


GO
CREATE NONCLUSTERED INDEX [IX_DateKey_PublicationNumLast6Months_WithIncluded]
    ON [dbo].[FactCompanyStatuses]([Date_key] ASC, [PublicationsNumLast6Months] ASC)
    INCLUDE([Company_key], [IsMegaChecked], [HasPaidPublishedVacs], [HasPaidPublicationsLeft], [PublicationsNumLast2Months], [MonthsNumLast6Months], [MonthsNumLast3Months], [MonthsNumLast2Months], [HasHotPublishedVacs], [HasHotPublicationsLeft], [HasCVDBAccess], [HasActivatedLogo], [HasActivatedProfile], [PublicationsNumLast3Months]);


GO
CREATE NONCLUSTERED INDEX [IX_HasPaidServices]
    ON [dbo].[FactCompanyStatuses]([HasPaidServices] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_FactCompanyStatuses_PaymentStatusKey_WithIncluded]
    ON [dbo].[FactCompanyStatuses]([PaymentStatusKey] ASC)
    INCLUDE([Date_key]);


GO
CREATE NONCLUSTERED INDEX [IX_VacancyDiffGroup]
    ON [dbo].[FactCompanyStatuses]([VacancyDiffGroup] ASC);

