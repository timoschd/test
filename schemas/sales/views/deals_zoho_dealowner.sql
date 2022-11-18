-- get closings and deal revenue per current day, week, month and dealowner and join image url to dealowner headshot  
CREATE VIEW sc.current_closings AS (  
with closings_day AS (
  SELECT
    COUNT(DISTINCT "Id"::text) AS deals_heute,
    "Art der Maßnahme"::text AS massnahme_art,
    "Owner Name"::text AS deal_besitzer,   
    SUM("Betrag 1"::numeric) + SUM("Betrag 2"::numeric) as betrag_heute, 
    "Auftragsdatum" As datum_heute
   FROM zoho."Deals"
   WHERE "Auftragsdatum" = CURRENT_DATE and "Stage" = 'Abgeschlossen'
   GROUP BY "Art der Maßnahme", "Owner Name", "Auftragsdatum"
  ),
closings_week AS (
  SELECT
    COUNT(DISTINCT "Id"::text) AS deals_diese_woche,
    "Art der Maßnahme"::text AS massnahme_art,
    "Owner Name"::text AS deal_besitzer,   
    SUM("Betrag 1"::numeric) + SUM("Betrag 2"::numeric) as betrag_diese_woche
    FROM zoho."Deals"
   WHERE  "Stage" = 'Abgeschlossen' AND date_trunc('week', "Auftragsdatum"::date) = date_trunc('week', CURRENT_DATE) -- diese Woche
   GROUP BY "Art der Maßnahme", "Owner Name"
  ),
closings_month AS (   
  SELECT
    COUNT(DISTINCT "Id"::text) AS deals_diesen_monat,
    "Art der Maßnahme"::text AS massnahme_art,
    "Owner Name"::text AS deal_besitzer,   
    SUM("Betrag 1"::numeric) + SUM("Betrag 2"::numeric) as betrag_diesen_monat
    FROM zoho."Deals"
   WHERE  "Stage" = 'Abgeschlossen' AND date_trunc('month', "Auftragsdatum"::date) = date_trunc('month', CURRENT_DATE) -- diesen Monat
   GROUP BY "Art der Maßnahme", "Owner Name"
),
sales_images AS (
  SELECT 
  "Full Name" as name_emp,
  headshot_image_url
  FROM zoho."Users"
 )


SELECT closings_month.deal_besitzer, closings_month.massnahme_art, COALESCE(deals_diesen_monat,0) as deals_diesen_monat, COALESCE(betrag_diesen_monat,0) as betrag_diesen_monat, COALESCE(deals_diese_woche,0) as deals_diese_woche, 
  COALESCE(betrag_diese_woche,0) as betrag_diese_woche, COALESCE(deals_heute,0) as deals_heute,  COALESCE(betrag_heute,0) as betrag_heute, sales_images.headshot_image_url
FROM closings_month
LEFT JOIN closings_week
    ON closings_month.deal_besitzer = closings_week.deal_besitzer AND closings_month.massnahme_art =  closings_week.massnahme_art
LEFT JOIN closings_day
    ON closings_month.deal_besitzer = closings_day.deal_besitzer AND closings_month.massnahme_art =  closings_day.massnahme_art
LEFT JOIN sales_images
    ON closings_month.deal_besitzer = sales_images.name_emp
);

