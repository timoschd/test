-- Creates stage db from datawarehouse db

-- stop all connections to stage
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'data_warehouse_stage'
    AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS data_warehouse_stage;


-- stop all connections to dwh
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'data_warehouse'
    AND pid <> pg_backend_pid();


-- copy datawarehouse db
CREATE DATABASE data_warehouse_stage
WITH TEMPLATE data_warehouse
OWNER rwx_user;