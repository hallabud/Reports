CREATE PROCEDURE [dbo].[usp_etl_Admin4DistributionStats]

AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @TodayDT DATETIME = CONVERT(DATE, GETDATE());
DECLARE @YesterdayDT DATETIME = DATEADD(DAY, -1, @TodayDT);

-- DistributionID - идентификатор рассылки в админ4
-- Нюанс - рассылка с определенным идентификатором может быть отредактирована и отправлена с другими параметрами в другую дату
-- Нюанс игнорируем так как планруется, что каждая отдельная рассылка будет создаваться со своим DistributionID

-- добавляем в таблицу-справочник отправленных рассылок новые данные
INSERT INTO Reporting.dbo.DimAdmin4Distribution (DistributionID, LetterSubject, StartDate, EndDate, FinishDate, TotalSubscribers, AddDate, DistributionName)
SELECT DistributionID, SL.LetterSubject, StartDate, EndDate, DATEADD(DAY, 13, CONVERT(DATE, EndDate)) AS FinishDate, SL.[Count] AS TotalSubscribers, GETDATE() AS AddDate, D.Name
FROM SRV16.RabotaUA2.dbo.Admin4_Distribution_SentLog SL
 JOIN SRV16.RabotaUA2.dbo.Admin4_Distribution D ON SL.DistributionID = D.ID
WHERE SL.[State] = 3 
 AND StartDate BETWEEN @YesterdayDT AND @TodayDT
 AND NOT EXISTS (SELECT * FROM Reporting.dbo.DimAdmin4Distribution WHERE DistributionID = SL.DistributionID);

-- определяем по каким рассылкам подсчитываем и сохраняем показатели
-- считаем и сохраняем показатели рассылки только в течении 2 недель после отправки
DECLARE @Distributions TABLE (DistributionID INT, RowNum INT);

-- FinishDate - это последняя дата, по которой мы считаем показатели
INSERT INTO @Distributions 
SELECT DistributionID, ROW_NUMBER() OVER(ORDER BY DistributionID) AS RowNum
FROM Reporting.dbo.DimAdmin4Distribution 
WHERE @YesterdayDT <= FinishDate

DECLARE @LastDistributionID INT = (SELECT MAX(DistributionID) FROM @Distributions);
DECLARE @LastRowNum INT = (SELECT RowNum FROM @Distributions WHERE DistributionID = @LastDistributionID)
DECLARE @i INT = 1;

DECLARE @Sent INT;
DECLARE @Delivered INT;
DECLARE @Opened INT;
DECLARE @Clicks INT;

DECLARE @DistributionID INT
SET @DistributionID = (SELECT DistributionID FROM @Distributions WHERE RowNum = @i);

WHILE @i <= @LastRowNum 

	BEGIN 
		
		-- 1) Emails sent | количество отправленных писем
		SELECT @Sent = COUNT(*) 
		FROM SRV16.RabotaUA2.dbo.Admin4_Distribution_SentEMail SE
		 JOIN Reporting.dbo.DimAdmin4Distribution A4D ON SE.DistributionID = A4D.DistributionID
		WHERE SE.DistributionID = @DistributionID
		 AND SE.SentDate BETWEEN A4D.StartDate AND @TodayDT;

		-- 2) Delivered | количество доставленных писем
		SELECT @Delivered = COUNT(*)
		FROM SRV16.RabotaUA2.dbo.Admin4_Distribution_SentEMail SE
		 JOIN SRV16.RabotaUA2.dbo.EMailSource ES ON SE.EMailID = ES.ID
		 JOIN Reporting.dbo.DimAdmin4Distribution A4D ON SE.DistributionID = A4D.DistributionID
		WHERE SE.DistributionID = @DistributionID
		 AND NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.EMail_BadBySMTP WHERE Email = ES.EMail)
		  AND SE.SentDate BETWEEN A4D.StartDate AND @TodayDT;

		--5) Unique opens | к-во уникальных открытий писем.
		SELECT @Opened = COUNT(DISTINCT EmailID)
		FROM SRV16.RabotaUA2.dbo.Admin4_Distribution_ViewLetter VL
		 JOIN Reporting.dbo.DimAdmin4Distribution A4D ON VL.DistributionID = A4D.DistributionID
		WHERE VL.DistributionID = @DistributionID
		 AND IsView = 1
		 AND VL.AddDate BETWEEN @YesterdayDT AND @TodayDT;

		--7) Unique clicks | количество уникальных переходов по ссылкам
		SELECT @Clicks = COUNT(DISTINCT EmailID)
		FROM SRV16.RabotaUA2.dbo.Admin4_Distribution_ViewLetter VL
		 JOIN Reporting.dbo.DimAdmin4Distribution A4D ON VL.DistributionID = A4D.DistributionID
		WHERE VL.DistributionID = @DistributionID
		 AND IsView = 0
		 AND VL.AddDate BETWEEN @YesterdayDT AND @TodayDT;
		
		IF NOT EXISTS (SELECT * FROM Reporting.dbo.FactAdmin4DistributionStats WHERE DistributionID = @DistributionID AND FullDate = @YesterdayDT)

			INSERT INTO Reporting.dbo.FactAdmin4DistributionStats (FullDate, DistributionID, Sent, Delivered, Opened, Clicked)
			VALUES (@YesterdayDT, @DistributionID, @Sent, @Delivered, @Opened, @Clicks);

			-- 4) Deliverability by Domain, % | процент доставки подоменно (ТОP-50)
			-- берем только те домены, на которые отправлено больше 1% писем из общего кол-ва в данной рассылке

		IF NOT EXISTS (SELECT * FROM Reporting.dbo.FactAdmin4DistributionStatsByDomain WHERE DistributionID = @DistributionID AND FullDate = @YesterdayDT)

			WITH C_Delivered AS
			 (
			SELECT SUBSTRING(ES.Email, CHARINDEX('@', ES.Email) + 1, 100500) AS Domain, COUNT(*) AS EmailsDelivered
			FROM SRV16.RabotaUA2.dbo.Admin4_Distribution_SentEMail SE
			 JOIN SRV16.RabotaUA2.dbo.EMailSource ES ON SE.EMailID = ES.ID
			WHERE SE.DistributionID = @DistributionID
			 AND NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.EMail_BadBySMTP WHERE Email = ES.EMail)
			GROUP BY SUBSTRING(ES.Email, CHARINDEX('@', ES.Email) + 1, 100500)
			 )
			 , C_Sent AS
			 (
			SELECT SUBSTRING(ES.Email, CHARINDEX('@', ES.Email) + 1, 100500) AS Domain, COUNT(*) AS EmailsSent
			FROM SRV16.RabotaUA2.dbo.Admin4_Distribution_SentEMail SE
			 JOIN SRV16.RabotaUA2.dbo.EMailSource ES ON SE.EMailID = ES.ID
			WHERE DistributionID = @DistributionID
			GROUP BY SUBSTRING(ES.Email, CHARINDEX('@', ES.Email) + 1, 100500)
			 )
			INSERT INTO Reporting.dbo.FactAdmin4DistributionStatsByDomain (DistributionID, FullDate, Domain, DeliveryRate, EmailsSent)
			SELECT TOP 50 @DistributionID AS DistributionID, @YesterdayDT AS FullDate, CS.Domain, 1. * CD.EmailsDelivered / CS.EmailsSent AS DeliveryRate, CS.EmailsSent
			FROM C_Delivered CD
			 JOIN C_Sent CS ON CD.Domain = CS.Domain
			WHERE CS.EmailsSent >= 0.01 * @Sent
			ORDER BY DeliveryRate DESC, CS.EmailsSent DESC;


		SET @i = @i + 1;		
		SET @DistributionID = (SELECT DistributionID FROM @Distributions WHERE RowNum = @i);

	END
