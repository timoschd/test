DROP MATERIALIZED VIEW IF EXISTS sc.union_ldc_materialized;

-- UNION leads, deals, closings
CREATE MATERIALIZED VIEW sc.union_ldc_materialized AS (
SELECT * FROM sc.leads
	UNION
SELECT * FROM sc.deals
	UNION
SELECT * FROM sc.closings

);

Create INDEX ON sc.union_ldc_materialized ("Id");

-- set owner 
ALTER MATERIALIZED View sc.union_ldc_materialized  OWNER TO read_only;