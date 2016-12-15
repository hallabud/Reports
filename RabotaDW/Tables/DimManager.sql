CREATE TABLE [dbo].[DimManager]
(
	[ManagerKey] [int] IDENTITY(1,1) NOT NULL,
    [ManagerId] INT NOT NULL, 
    [Name] NVARCHAR(500) NULL, 
    [Email] NVARCHAR(256) NULL, 
    [DepartmentId] TINYINT NULL, 
    [AddDate] DATETIME NULL, 
    [DeleteDate] DATETIME NULL, 
    [STMId] INT NULL, 
    [SMId] INT NULL, 
    [IsLoyaltyGroup] BIT NOT NULL, 
    [StartDate] DATETIME NOT NULL, 
    [EndDate] DATETIME NULL 
)
