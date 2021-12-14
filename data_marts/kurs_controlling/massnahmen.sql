 -- Create Table massnahmen
 Create TABLE kc.massnahmen AS
 SELECT massnahmen_organisation_courses.app_item_id,
    massnahmen_organisation_courses.app_item_id_formatted AS massnahmen_id,
	CASE massnahmen_organisation_courses.app_item_id_formatted WHEN 'CRSE1294' THEN 'CRSE2551duplicate'
	ELSE concat('CRSE', massnahmen_organisation_courses.courses_sales_management::json ->> 'app_item_id'::text)
	END AS massnahmen_id_sales,
	massnahmen_organisation_courses.titel AS massnahmen_titel,
	massnahmen_organisation_courses.gesamt_status AS massnahme_status,
	massnahmen_organisation_courses.course_status AS erweiterter_status,
	massnahmen_organisation_courses.massnahmen_nr_2,
	massnahmen_organisation_courses.uw as wochen,
	massnahmen_organisation_courses.ue_2 as unterrichtseinheiten,
	massnahmen_organisation_courses.dkz_nummer,
	(massnahmen_organisation_courses.gultig_bis_2::json->>'start_date')::date as gueltig_bis,
	massnahmen_organisation_courses.calcgebuehren::numeric AS gebuehren,
	massnahmen_organisation_courses.massnahmenbogen_item_id::integer,
	massnahmen_organisation_courses.massnahmenbogen_titel	
  FROM podio.massnahmen_organisation_courses
		   
  -- Create primary key & not null 
CREATE UNIQUE INDEX ON kc.massnahmen (massnahmen_id_sales);
  
ALTER TABLE IF EXISTS kc.massnahmen
    ADD PRIMARY KEY (massnahmen_id);
   
-- Set table owner
ALTER TABLE kc.massnahmen OWNER TO read_only;