use database PROVISIONING_DB;
use schema ADMIN;
CREATE OR REPLACE PROCEDURE PROVISION_SCHEMA_WITH(
    DATABASE_NAME VARCHAR,
    SCHEMA_NAME VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    -- Variables for role determination
    env_prefix VARCHAR;
    db_type VARCHAR;
    rw_role VARCHAR;
    ro_role VARCHAR;
    result_message VARCHAR;
    error_message VARCHAR;
    
BEGIN
    -- Determine environment prefix (DEV or PROD)
    env_prefix := CASE 
        WHEN CONTAINS(UPPER(DATABASE_NAME), 'DEV') THEN 'DEV'
        WHEN CONTAINS(UPPER(DATABASE_NAME), 'PROD') THEN 'PROD'
        ELSE NULL
    END;

    IF (env_prefix = 'DEV') THEN
        EXECUTE IMMEDIATE 'USE ROLE DEV_SYSADMIN';
    ELSEIF (env_prefix = 'PROD') THEN
        EXECUTE IMMEDIATE 'USE ROLE PROD_SYSADMIN';
    ELSE
        RETURN 'Error: Database name must contain either DEV or PROD';
    END IF;
    
    -- Determine database type
    db_type := CASE
        WHEN CONTAINS(UPPER(DATABASE_NAME), 'RAW') THEN 'RAW'
        WHEN CONTAINS(UPPER(DATABASE_NAME), 'TRANSFORMATION') THEN 'TRANSFORM'
        WHEN CONTAINS(UPPER(DATABASE_NAME), 'ANALYTICS') THEN 'ANALYTICS'
        ELSE NULL
    END;
    
    IF (db_type IS NULL) THEN
        RETURN 'Error: Unable to determine database type (RAW, TRANSFORMATION, or ANALYTICS)';
    END IF;
    
    -- Set role names based on database type
    CASE 
        WHEN db_type = 'RAW' THEN
            rw_role := 'AR_' || env_prefix || '_RAW_RW';
            ro_role := 'AR_' || env_prefix || '_RAW_RO';
        WHEN db_type = 'TRANSFORM' THEN
            rw_role := 'AR_' || env_prefix || '_TRANSFORM_RW';
            ro_role := 'AR_' || env_prefix || '_TRANSFORM_RO';
        WHEN db_type = 'ANALYTICS' THEN
            rw_role := 'AR_' || env_prefix || '_REPORTING_RW';
            ro_role := 'AR_' || env_prefix || '_REPORTING_RO';
    END CASE;
    
    -- Create the schema
    EXECUTE IMMEDIATE 'CREATE SCHEMA IF NOT EXISTS ' || DATABASE_NAME || '.' || SCHEMA_NAME;

    EXECUTE IMMEDIATE 'USE ROLE SECURITYADMIN';
    
    -- Grant privileges to RW role
    -- Schema-level privileges based on database type
    IF (db_type IN ('RAW', 'TRANSFORM')) THEN
        EXECUTE IMMEDIATE 'GRANT USAGE,MONITOR,CREATE TABLE,CREATE DYNAMIC TABLE,CREATE EVENT TABLE,CREATE EXTERNAL TABLE,CREATE ICEBERG TABLE,CREATE VIEW,CREATE MATERIALIZED VIEW,CREATE NETWORK RULE,CREATE MASKING POLICY,CREATE ROW ACCESS POLICY,CREATE SECRET,CREATE STAGE,CREATE FILE FORMAT,CREATE SEQUENCE,CREATE FUNCTION,CREATE PIPE,CREATE STREAM,CREATE TASK,CREATE PROCEDURE,ADD SEARCH OPTIMIZATION,CREATE SESSION POLICY ON SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || rw_role;
    ELSE -- ANALYTICS/REPORTING
        EXECUTE IMMEDIATE 'GRANT USAGE,MONITOR,CREATE TABLE,CREATE VIEW,CREATE MATERIALIZED VIEW ON SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || rw_role;
    END IF;
    
    -- Future objects privileges for RW role
    EXECUTE IMMEDIATE 'GRANT ALL ON FUTURE TABLES IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || rw_role;
    EXECUTE IMMEDIATE 'GRANT ALL ON FUTURE VIEWS IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || rw_role;
    EXECUTE IMMEDIATE 'GRANT ALL ON FUTURE MATERIALIZED VIEWS IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || rw_role;
    
    IF (db_type IN ('RAW', 'TRANSFORM')) THEN
        EXECUTE IMMEDIATE 'GRANT ALL ON FUTURE EXTERNAL TABLES IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || rw_role;
        EXECUTE IMMEDIATE 'GRANT ALL ON FUTURE FILE FORMATS IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || rw_role;
        EXECUTE IMMEDIATE 'GRANT ALL ON FUTURE STREAMS IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || rw_role;
        EXECUTE IMMEDIATE 'GRANT ALL ON FUTURE STAGES IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || rw_role;
        EXECUTE IMMEDIATE 'GRANT ALL ON FUTURE TASKS IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || rw_role;
        EXECUTE IMMEDIATE 'GRANT ALL ON FUTURE FUNCTIONS IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || rw_role;
        EXECUTE IMMEDIATE 'GRANT ALL ON FUTURE SEQUENCES IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || rw_role;
        EXECUTE IMMEDIATE 'GRANT ALL ON FUTURE PROCEDURES IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || rw_role;
        EXECUTE IMMEDIATE 'GRANT ALL ON FUTURE PIPES IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || rw_role;
    END IF;
    
    -- Grant privileges to RO role
    -- First ensure the role has database usage
    EXECUTE IMMEDIATE 'GRANT USAGE ON DATABASE ' || DATABASE_NAME || ' TO ROLE ' || ro_role;
    
    -- Schema-level privileges
    EXECUTE IMMEDIATE 'GRANT USAGE ON SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || ro_role;
    
    -- Current objects (if any)
    EXECUTE IMMEDIATE 'GRANT SELECT ON ALL TABLES IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || ro_role;
    
    -- Future objects privileges for RO role
    EXECUTE IMMEDIATE 'GRANT SELECT ON FUTURE TABLES IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || ro_role;
    EXECUTE IMMEDIATE 'GRANT SELECT ON FUTURE VIEWS IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || ro_role;
    EXECUTE IMMEDIATE 'GRANT SELECT,REFERENCES ON FUTURE MATERIALIZED VIEWS IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || ro_role;
    
    IF (db_type IN ('RAW', 'TRANSFORM')) THEN
        EXECUTE IMMEDIATE 'GRANT SELECT ON FUTURE EXTERNAL TABLES IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || ro_role;
        EXECUTE IMMEDIATE 'GRANT USAGE ON FUTURE FILE FORMATS IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || ro_role;
        EXECUTE IMMEDIATE 'GRANT SELECT ON FUTURE STREAMS IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || ro_role;
        EXECUTE IMMEDIATE 'GRANT USAGE,READ ON FUTURE STAGES IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || ro_role;
        EXECUTE IMMEDIATE 'GRANT MONITOR ON FUTURE TASKS IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || ro_role;
        EXECUTE IMMEDIATE 'GRANT USAGE ON FUTURE FUNCTIONS IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || ro_role;
        EXECUTE IMMEDIATE 'GRANT USAGE ON FUTURE PROCEDURES IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || ro_role;
        EXECUTE IMMEDIATE 'GRANT MONITOR ON FUTURE PIPES IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || ro_role;
        EXECUTE IMMEDIATE 'GRANT USAGE ON FUTURE SEQUENCES IN SCHEMA ' || DATABASE_NAME || '.' || SCHEMA_NAME || ' TO ROLE ' || ro_role;
    END IF;
    
    -- Success message
    result_message := 'Successfully provisioned schema ' || DATABASE_NAME || '.' || SCHEMA_NAME || 
                     ' with privileges for roles: ' || rw_role || ' (RW) and ' || ro_role || ' (RO)';
    
    RETURN result_message;
    
EXCEPTION
    WHEN OTHER THEN
        RETURN 'Error: ' || SQLERRM;
END;
$$;

-- Example usage:
-- CALL PROVISION_SCHEMA_WITH_RBAC('DEV_RAW_DB', 'NEW_SCHEMA');
-- CALL PROVISION_SCHEMA_WITH_RBAC('PROD_ANALYTICS_DB', 'analytics_new_id');
-- CALL PROVISION_SCHEMA_WITH_RBAC('DEV_TRANSFORMATION_DB', 'TEMP_PROCESSING');