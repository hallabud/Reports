CREATE TABLE [dbo].[DimPaymentStatus] (
    [PaymentStatusKey] TINYINT       NOT NULL,
    [PaymentStatus]    NVARCHAR (50) NOT NULL,
    CONSTRAINT [PK_DimPaymentStatus] PRIMARY KEY CLUSTERED ([PaymentStatusKey] ASC)
);

