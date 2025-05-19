CREATE OR REPLACE PROCEDURE VALIDATE_USER_ROLES_JSON(
    p_input_filename STRING -- Name of the JSON file
)
RETURNS VARIANT
LANGUAGE SQL
AS
DECLARE
    result VARIANT;
    v_file_check VARIANT;
BEGIN
    -- Create a temporary table to hold parsed JSON data
    CREATE OR REPLACE TEMPORARY TABLE temp_user_roles_validation (
        username VARCHAR(255),
        role_name VARCHAR(255)
    );
    
    -- First, let's verify the file exists and get a count of records
    SELECT OBJECT_CONSTRUCT(
        'file_records', COUNT(*),
        'file_exists', IFF(COUNT(*) > 0, TRUE, FALSE)
    )
    INTO :v_file_check
    FROM @test_stage (
        FILE_FORMAT => 'my_json_format',
        PATTERN => :p_input_filename
    );
    
    -- Load JSON data into temp table using the provided stage and filename
    INSERT INTO temp_user_roles_validation (username, role_name)
    SELECT
        $1:username::STRING,
        $1:role::STRING
    FROM @test_stage (
        FILE_FORMAT => 'my_json_format',
        PATTERN => :p_input_filename
    );
    
    -- Find records that would be inserted (new combinations)
    WITH new_records AS (
        SELECT 
            v.username, 
            v.role_name
        FROM temp_user_roles_validation v
        LEFT JOIN ROLE_PROVISIONING p
            ON v.username = p.username
            AND v.role_name = p.role_name
        WHERE p.username IS NULL
    ),
    
    -- -- Find records that would be updated (existing combinations)
    -- updated_records AS (
    --     SELECT 
    --         v.username, 
    --         v.role_name
    --     FROM temp_user_roles_validation v
    --     JOIN ROLE_PROVISIONING p
    --         ON v.username = p.username
    --         AND v.role_name = p.role_name
    -- ),
    
    -- Find records that would be marked for revocation
    revoked_records AS (
        SELECT 
            p.username, 
            p.role_name
        FROM ROLE_PROVISIONING p
        WHERE NOT EXISTS (
            SELECT 1
            FROM temp_user_roles_validation v
            WHERE v.username = p.username
            AND v.role_name = p.role_name
        )
        AND p.is_revoked = FALSE
    ),
    
    -- Find potential data issues
    validation_issues AS (
        SELECT
            v.username,
            v.role_name,
            'Empty username' AS issue_type
        FROM temp_user_roles_validation v
        WHERE v.username IS NULL OR TRIM(v.username) = ''
        
        UNION ALL
        
        SELECT
            v.username,
            v.role_name,
            'Empty role' AS issue_type
        FROM temp_user_roles_validation v
        WHERE v.role_name IS NULL OR TRIM(v.role_name) = ''
    ),
    
    -- Compile all results
    summary AS (
        SELECT OBJECT_CONSTRUCT(
            'status', 'success',
            'file_records', v_file_check:file_records,
            'would_be_inserted', (SELECT COUNT(*) FROM new_records),
            'would_be_revoked', (SELECT COUNT(*) FROM revoked_records),
            'validation_issues', (SELECT COUNT(*) FROM validation_issues),
            'new_records', (SELECT ARRAY_AGG(OBJECT_CONSTRUCT('username', username, 'role_name', role_name)) FROM new_records LIMIT 100),
            'records_to_revoke', (SELECT ARRAY_AGG(OBJECT_CONSTRUCT('username', username, 'role_name', role_name)) FROM revoked_records LIMIT 100),
            'issues', (SELECT ARRAY_AGG(OBJECT_CONSTRUCT('username', username, 'role_name', role_name, 'issue', issue_type)) FROM validation_issues)
        ) AS result_obj
    )
    
    SELECT result_obj
    INTO :result
    FROM summary;
    
    -- Clean up
    DROP TABLE IF EXISTS temp_user_roles_validation;
    
    RETURN result;
END;