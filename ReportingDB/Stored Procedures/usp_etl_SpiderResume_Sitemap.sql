CREATE PROCEDURE [dbo].[usp_etl_SpiderResume_Sitemap]

AS

-- добавить айдишки резюме из сайтмапа ворка

INSERT INTO Reporting.dbo.Spider_Resume
SELECT SLSR.SpiderResumeID, SLSR.ResumeLink, MIN(SLSR.AddDate)
FROM SRV16.RabotaUA2.dbo.SpiderLoad_Sitemap_Resume SLSR WITH (NOLOCK)
WHERE NOT EXISTS (SELECT * FROM Reporting.dbo.Spider_Resume SR WHERE SR.SpiderResumeID = SLSR.SpiderResumeID)
GROUP BY SpiderResumeID, ResumeLink;


-- Сохраняем даты резюме, затяную с ворка
INSERT INTO Reporting.dbo.Spider_Resume_Dates
SELECT DISTINCT SpiderResumeID, ResumeDate
 , CASE 
    WHEN EXISTS (SELECT * FROM SRV16.RabotaUA2.dbo.SpiderLoad_Sitemap_Resume WITH (NOLOCK) WHERE SpiderResumeID = SLSR.SpiderResumeID AND ResumeDate < SLSR.ResumeDate) THEN 0
	ELSE 1
   END
FROM SRV16.RabotaUA2.dbo.SpiderLoad_Sitemap_Resume SLSR  WITH (NOLOCK)
WHERE NOT EXISTS (SELECT * FROM Reporting.dbo.Spider_Resume_Dates WHERE SpiderResumeID = SLSR.SpiderResumeID AND ResumeDate = SLSR.ResumeDate);