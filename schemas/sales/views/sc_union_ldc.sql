DROP VIEW IF EXISTS sc.union_ldc;

-- UNION leads, deals, closings
CREATE VIEW sc.union_ldc AS (
SELECT * FROM sc.leads
	UNION
SELECT * FROM sc.deals
	UNION
SELECT * FROM sc.closings);

-- set user read Only
ALTER TABLE sc.union_ldc OWNER TO read_only;