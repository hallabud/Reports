
CREATE VIEW [dbo].[vw_FactCompanyStatuses]
	WITH SCHEMABINDING

AS

SELECT Company_key, Date_key, Rating, IsMegaChecked, IsPriority2013, HasPaidPublishedVacs, HasPaidPublicationsLeft, HasHotPublishedVacs, HasHotPublicationsLeft, HasCVDBAccess, HasActivatedLogo, HasActivatedProfile, MonthsFromRegDate, PublicationsNum, PublicationsNumLast6Months, PublicationsNumLast3Months, PublicationsNumLast2Months, MonthsNumLast6Months, MonthsNumLast3Months, MonthsNumLast2Months, VacancyNum, WorkVacancyNum, AvgLast3Month, IndexActivity, IndexAttraction, VacancyDiffGroup, FakeVacancyNum, FakeVacancyDiffGroup, UnqVacancyNum, UnqWorkVacancyNum, HasPaidServices, PaymentStatusKey 
FROM [dbo].[FactCompanyStatusesY2013]

UNION ALL

SELECT Company_key, Date_key, Rating, IsMegaChecked, IsPriority2013, HasPaidPublishedVacs, HasPaidPublicationsLeft, HasHotPublishedVacs, HasHotPublicationsLeft, HasCVDBAccess, HasActivatedLogo, HasActivatedProfile, MonthsFromRegDate, PublicationsNum, PublicationsNumLast6Months, PublicationsNumLast3Months, PublicationsNumLast2Months, MonthsNumLast6Months, MonthsNumLast3Months, MonthsNumLast2Months, VacancyNum, WorkVacancyNum, AvgLast3Month, IndexActivity, IndexAttraction, VacancyDiffGroup, FakeVacancyNum, FakeVacancyDiffGroup, UnqVacancyNum, UnqWorkVacancyNum, HasPaidServices, PaymentStatusKey 
FROM [dbo].[FactCompanyStatusesY2014]

UNION ALL

SELECT Company_key, Date_key, Rating, IsMegaChecked, IsPriority2013, HasPaidPublishedVacs, HasPaidPublicationsLeft, HasHotPublishedVacs, HasHotPublicationsLeft, HasCVDBAccess, HasActivatedLogo, HasActivatedProfile, MonthsFromRegDate, PublicationsNum, PublicationsNumLast6Months, PublicationsNumLast3Months, PublicationsNumLast2Months, MonthsNumLast6Months, MonthsNumLast3Months, MonthsNumLast2Months, VacancyNum, WorkVacancyNum, AvgLast3Month, IndexActivity, IndexAttraction, VacancyDiffGroup, FakeVacancyNum, FakeVacancyDiffGroup, UnqVacancyNum, UnqWorkVacancyNum, HasPaidServices, PaymentStatusKey 
FROM [dbo].[FactCompanyStatusesY2015]

UNION ALL

SELECT Company_key, Date_key, Rating, IsMegaChecked, IsPriority2013, HasPaidPublishedVacs, HasPaidPublicationsLeft, HasHotPublishedVacs, HasHotPublicationsLeft, HasCVDBAccess, HasActivatedLogo, HasActivatedProfile, MonthsFromRegDate, PublicationsNum, PublicationsNumLast6Months, PublicationsNumLast3Months, PublicationsNumLast2Months, MonthsNumLast6Months, MonthsNumLast3Months, MonthsNumLast2Months, VacancyNum, WorkVacancyNum, AvgLast3Month, IndexActivity, IndexAttraction, VacancyDiffGroup, FakeVacancyNum, FakeVacancyDiffGroup, UnqVacancyNum, UnqWorkVacancyNum, HasPaidServices, PaymentStatusKey 
FROM [dbo].[FactCompanyStatusesY2016]

UNION ALL

SELECT Company_key, Date_key, Rating, IsMegaChecked, IsPriority2013, HasPaidPublishedVacs, HasPaidPublicationsLeft, HasHotPublishedVacs, HasHotPublicationsLeft, HasCVDBAccess, HasActivatedLogo, HasActivatedProfile, MonthsFromRegDate, PublicationsNum, PublicationsNumLast6Months, PublicationsNumLast3Months, PublicationsNumLast2Months, MonthsNumLast6Months, MonthsNumLast3Months, MonthsNumLast2Months, VacancyNum, WorkVacancyNum, AvgLast3Month, IndexActivity, IndexAttraction, VacancyDiffGroup, FakeVacancyNum, FakeVacancyDiffGroup, UnqVacancyNum, UnqWorkVacancyNum, HasPaidServices, PaymentStatusKey 
FROM [dbo].[FactCompanyStatusesY2017]

UNION ALL

SELECT Company_key, Date_key, Rating, IsMegaChecked, IsPriority2013, HasPaidPublishedVacs, HasPaidPublicationsLeft, HasHotPublishedVacs, HasHotPublicationsLeft, HasCVDBAccess, HasActivatedLogo, HasActivatedProfile, MonthsFromRegDate, PublicationsNum, PublicationsNumLast6Months, PublicationsNumLast3Months, PublicationsNumLast2Months, MonthsNumLast6Months, MonthsNumLast3Months, MonthsNumLast2Months, VacancyNum, WorkVacancyNum, AvgLast3Month, IndexActivity, IndexAttraction, VacancyDiffGroup, FakeVacancyNum, FakeVacancyDiffGroup, UnqVacancyNum, UnqWorkVacancyNum, HasPaidServices, PaymentStatusKey 
FROM [dbo].[FactCompanyStatusesY2018]

UNION ALL

SELECT Company_key, Date_key, Rating, IsMegaChecked, IsPriority2013, HasPaidPublishedVacs, HasPaidPublicationsLeft, HasHotPublishedVacs, HasHotPublicationsLeft, HasCVDBAccess, HasActivatedLogo, HasActivatedProfile, MonthsFromRegDate, PublicationsNum, PublicationsNumLast6Months, PublicationsNumLast3Months, PublicationsNumLast2Months, MonthsNumLast6Months, MonthsNumLast3Months, MonthsNumLast2Months, VacancyNum, WorkVacancyNum, AvgLast3Month, IndexActivity, IndexAttraction, VacancyDiffGroup, FakeVacancyNum, FakeVacancyDiffGroup, UnqVacancyNum, UnqWorkVacancyNum, HasPaidServices, PaymentStatusKey 
FROM [dbo].[FactCompanyStatusesY2019];

