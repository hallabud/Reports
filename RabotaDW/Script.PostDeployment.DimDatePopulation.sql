/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

DECLARE @StartDate date = '2000-01-01';
DECLARE @EndDate date = '2020-12-31';

IF NOT EXISTS (SELECT * FROM dbo.DimDate)

	EXECUTE [dbo].[uspDimDatePopulate]  @StartDate, @EndDate;

IF NOT EXISTS (SELECT * FROM dbo.DimNotebookState)

	EXECUTE dbo.uspDimNotebookStatePopulate;