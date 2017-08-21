 CREATE PROCEDURE [dbo].[uspDimNotebookStatePopulate]
	
 AS
	
INSERT INTO dbo.DimNotebookState (NotebookStateID, NotebookStateName)
VALUES 
	(0, 'Неизвестно'), 
	(1, 'новый'), 
	(2, 'ожидание активации'), 
	(3, 'неактивирован'), 
	(4, 'черный список'), 
	(5, 'проверенный'), 
	(6, 'неопределенный'), 
	(7, 'МЕГА проверенный');