CREATE PROCEDURE [dbo].[usp_etl_DimSpiderCompany]

AS

INSERT INTO Reporting.dbo.DimSpiderCompany (
   SpiderCompanyID
 , SpiderSource_key
 , RegDate_key
 , NotebookId
 , CompanyID
 , CompanyName
 , CompanyWebsite
 , IsAgency
 , IsApproved
 , CityId
 , AddDate
 , UpdateDate
 , Rating)
SELECT 
   ID
 , Source
 , DD.Date_key
 , SC.NotebookId
 , SC.CompanyID
 , SC.Name
 , NULLIF(SC.Site,'')
 , ISNULL(SC.Agency, 0)
 , ISNULL(SC.IsApproved, 0) AS IsApproved
 , SC.CityId
 , GETDATE()
 , GETDATE()
 , SC.Rating
FROM SRV16.RabotaUA2.dbo.SpiderCompany SC
 JOIN Reporting.dbo.DimDate DD ON dbo.fnGetDatePart(SC.AddDate) = DD.FullDate
WHERE NOT EXISTS (SELECT * FROM Reporting.dbo.DimSpiderCompany DSC WHERE DSC.SpiderCompanyID = SC.ID);

UPDATE DSC
SET 
   NotebookID = SC.NotebookID
 , UpdateDate = GETDATE()
FROM Reporting.dbo.DimSpiderCompany DSC
 JOIN SRV16.RabotaUA2.dbo.SpiderCompany SC ON DSC.SpiderCompanyID = SC.ID
WHERE DSC.NotebookID IS NULL AND SC.NotebookID IS NOT NULL;

UPDATE DSC
SET
   IsApproved = SC.IsApproved
 , UpdateDate = GETDATE()
FROM Reporting.dbo.DimSpiderCompany DSC
 JOIN SRV16.RabotaUA2.dbo.SpiderCompany SC ON DSC.SpiderCompanyID = SC.ID
WHERE DSC.IsApproved = 0 AND SC.IsApproved = 1;

UPDATE DSC
SET
   CityId = SC.CityId
 , UpdateDate = GETDATE()
FROM Reporting.dbo.DimSpiderCompany DSC
 JOIN SRV16.RabotaUA2.dbo.SpiderCompany SC ON DSC.SpiderCompanyID = SC.ID
WHERE (DSC.CityId IS NULL AND SC.CityId IS NOT NULL) OR (DSC.CityId <> SC.CityId);

UPDATE DSC
SET
   Rating = SC.Rating
 , UpdateDate = GETDATE()
FROM Reporting.dbo.DimSpiderCompany DSC
 JOIN SRV16.RabotaUA2.dbo.SpiderCompany SC ON DSC.SpiderCompanyID = SC.ID
WHERE (DSC.Rating IS NULL AND SC.Rating IS NOT NULL) OR (DSC.Rating <> SC.Rating);

-- удаляем те блокноты ворка, которых уже нет в продакшн-базе
DELETE FSCI 
FROM DimSpiderCompany DSC
 JOIN dbo.FactSpiderCompanyIndexes FSCI ON DSC.SpiderCompanyID = FSCI.SpiderCompanyID
WHERE SpiderSource_key = 1
 AND NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.SpiderCompany WITH (NOLOCK) WHERE Source = 1 AND ID = DSC.SpiderCompanyID);

DELETE DSC
FROM DimSpiderCompany DSC
WHERE SpiderSource_key = 1
 AND NOT EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.SpiderCompany WITH (NOLOCK) WHERE Source = 1 AND ID = DSC.SpiderCompanyID);