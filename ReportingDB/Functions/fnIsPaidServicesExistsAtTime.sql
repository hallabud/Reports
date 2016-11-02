
CREATE FUNCTION [dbo].[fnIsPaidServicesExistsAtTime] (
	@NotebookID INT,
	@Date DATETIME
)
RETURNS BIT
/**************************************************************************************************
 MODIFIED BY:	Andrew Smiyan
 MODIFIED ON:	29.08.2012
 COMMENTS	:	Не учитываем пополнения с типом размещения "Ежемесячное пополнение базовыми".
				Task #9126.
***************************************************************************************************
 MODIFIED BY:	Andrew Smiyan
 MODIFIED ON:	28.03.2012
 COMMENTS	:	Добавлена обработка билетов "горячих" вакансий.
				Task #8617.
***************************************************************************************************
 CREATED BY	:	Andrew Smiyan
 CREATED ON	:	28.04.2011
 COMMENTS	:	Проверка на наличие у блокнота @NotebookID платных сервисов на дату @Date:
				- количество билетов;
				- доступ к просмотру базы резюме;
				- наличие хотя бы одного пополнения счета вакансий (кроме "тестового размещения").
***************************************************************************************************/
AS
BEGIN
	IF EXISTS(SELECT NotebookID FROM SRV16.RabotaUA2.dbo.TemporalPayment WITH (NOLOCK) 
				WHERE NotebookID = @NotebookID AND @Date BETWEEN StartDate AND EndDate AND Price > 0)
		RETURN 1

	DECLARE @TicketCount INT

	SELECT @TicketCount = SUM(NewValue)
	FROM (
		SELECT NewValue, ROW_NUMBER() OVER (PARTITION BY Field ORDER BY DateOfUpd DESC) AS Number
		FROM SRV16.RabotaUA2.dbo.NotebookCompany_History WITH (NOLOCK)
		WHERE NotebookID = @NotebookID AND DateOfUpd <= @Date 
			AND Field IN ('rtVacancyStandart', 'rtVacancyDesigned', 'rtVacancyHot')
		) A
	WHERE Number = 1

	IF @TicketCount > 0 
			AND EXISTS(SELECT * FROM SRV16.RabotaUA2.dbo.TicketPayment WITH (NOLOCK) 
						WHERE NotebookID = @NotebookID AND State = 10 AND TicketPaymentTypeID NOT IN (5, 6)
							AND @Date BETWEEN AddDate AND ExpiryDate)
		RETURN 1

	DECLARE @Day SMALLINT
	SET @Day = dbo.fnDayByDate(@Date)

	SELECT @TicketCount = NewValue
	FROM (
		SELECT NewValue, ROW_NUMBER() OVER (PARTITION BY Field ORDER BY DateOfUpd DESC) AS Number
		FROM SRV16.RabotaUA2.dbo.NotebookCompany_History WITH (NOLOCK)
		WHERE NotebookID = @NotebookID AND DateOfUpd <= @Date AND Field = 'rtVacancyRegional'
		) A
	WHERE Number = 1

	IF @TicketCount > 0 
			AND EXISTS(SELECT * FROM SRV16.RabotaUA2.dbo.RegionalTicketPayment WITH (NOLOCK) 
						WHERE NotebookID = @NotebookID AND State = 10 AND TicketPaymentTypeID NOT IN (5, 6)
							AND DateValid >= @Day AND AddDate <= @Date)
		RETURN 1

	IF EXISTS(SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompany_History WITH (NOLOCK)
				WHERE NotebookID = @NotebookID AND Field IN ('rtVacancyStandart', 'rtVacancyDesigned', 'rtVacancyHot') 
					AND DateOfUpd BETWEEN @Date - 28 AND @Date)
			AND EXISTS(SELECT * FROM SRV16.RabotaUA2.dbo.TicketPayment WITH (NOLOCK) 
						WHERE NotebookID = @NotebookID AND State = 10 AND TicketPaymentTypeID NOT IN (5, 6)
							AND AddDate <= @Date AND ExpiryDate >= @Date - 28)
		RETURN 1

	IF EXISTS(SELECT * FROM SRV16.RabotaUA2.dbo.NotebookCompany_History WITH (NOLOCK)
				WHERE NotebookID = @NotebookID AND Field = 'rtVacancyRegional' AND DateOfUpd BETWEEN @Date - 28 AND @Date)
			AND EXISTS(SELECT * FROM SRV16.RabotaUA2.dbo.RegionalTicketPayment WITH (NOLOCK) 
						WHERE NotebookID = @NotebookID AND State = 10 AND TicketPaymentTypeID NOT IN (5, 6)
							AND AddDate <= @Date AND DateValid >= @Day - 28)
		RETURN 1

	RETURN 0
END
