
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-02-25
-- Description:	Процедура возвращает список групп сервиса
-- ======================================================================================================

CREATE PROCEDURE [dbo].[usp_ssrs_Dataset_ServiceGroups]

AS

SELECT ID, Name 
FROM Analytics.dbo.OrderService_Group