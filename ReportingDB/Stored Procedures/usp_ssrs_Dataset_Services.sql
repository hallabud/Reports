
-- ======================================================================================================
-- Author:		michael <michael@rabota.ua>
-- Create date: 2016-02-25
-- Description:	Процедура возвращает список всех видов сервиса
-- ======================================================================================================

CREATE PROCEDURE [dbo].[usp_ssrs_Dataset_Services]

AS

SELECT ID, Name, GroupID
FROM Analytics.dbo.OrderService
ORDER BY GroupID, Name
