DROP VIEW IF EXISTS sc.union_ldc;

-- UNION leads, deals, closings
CREATE VIEW sc.union_ldc AS (
SELECT * FROM sc.leads
	UNION
SELECT * FROM deals
	UNION
SELECT * FROM closings

);


-- set owner 
ALTER View sc.union_ldc OWNER TO read_only;