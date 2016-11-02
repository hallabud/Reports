CREATE TABLE [dbo].[EmployeeKPIs] (
    [Date_key]                         INT NOT NULL,
    [EmailsWithActiveSubscriptionsNum] INT NOT NULL,
    CONSTRAINT [PK_EmployeeKPIs] PRIMARY KEY CLUSTERED ([Date_key] ASC),
    CONSTRAINT [FK_EmployeeKPIs_DimDate] FOREIGN KEY ([Date_key]) REFERENCES [dbo].[DimDate] ([Date_key])
);

