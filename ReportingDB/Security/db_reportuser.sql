CREATE ROLE [db_reportuser]
    AUTHORIZATION [dbo];


GO
ALTER ROLE [db_reportuser] ADD MEMBER [RABOTA\SQLManagement];


GO
ALTER ROLE [db_reportuser] ADD MEMBER [RABOTA\SQLPM];


GO
ALTER ROLE [db_reportuser] ADD MEMBER [RABOTA\SQLEmployee];


GO
ALTER ROLE [db_reportuser] ADD MEMBER [RABOTA\SQLSalesforce];

