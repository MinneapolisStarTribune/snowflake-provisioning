CREATE OR REPLACE PROCEDURE BULK_INSERT_USER_ROLES_JSON(
    -- p_input_stage STRING,  -- Stage where input file is located
    p_input_filename STRING  -- Name of the JSON file
)
RETURNS VARIANT
LANGUAGE SQL
AS
DECLARE
    result VARIANT;
    v_row_count NUMBER;
    v_file_check VARIANT;
    rows_inserted NUMBER DEFAULT 0;
BEGIN
    -- Create a temporary table to hold parsed JSON data
    CREATE OR REPLACE TEMPORARY TABLE temp_user_roles (
        username VARCHAR(255),
        role_name VARCHAR(255)
    );

    -- First, let's verify the file exists and get a count of records
    SELECT OBJECT_CONSTRUCT(
        'file_records', COUNT(*)
    )
    INTO :v_file_check
    FROM @test_stage (
        FILE_FORMAT => 'my_json_format',
        PATTERN => :p_input_filename
    );

    -- Load JSON data into temp table using the provided stage and filename
    INSERT INTO temp_user_roles (username, role_name)
    SELECT 
        $1:username::STRING,
        $1:role::STRING
    FROM @test_stage (
        FILE_FORMAT => 'my_json_format',
        PATTERN => :p_input_filename
    );

    -- Perform the merge operation
    MERGE INTO ROLE_PROVISIONING AS target
    USING (
        SELECT DISTINCT username, role_name FROM temp_user_roles
        UNION ALL
        --Make sure we get anything that's been removed from the file
        SELECT username, role_name FROM role_provisioning 
        WHERE NOT EXISTS (
            SELECT 1 FROM temp_user_roles t 
            WHERE t.username = role_provisioning.username 
            AND t.role_name = role_provisioning.role_name
        )
    ) AS source
    ON target.username = source.username 
    AND target.role_name = source.role_name
    --If the user/role combination is not in the table, insert them
    WHEN NOT MATCHED THEN 
        INSERT (
            username, 
            role_name, 
            is_provisioned, 
            requested_date
        )
        VALUES (
            source.username, 
            source.role_name, 
            FALSE, 
            CURRENT_TIMESTAMP()
        )
    --If the user/role combination was removed from the file, update their role to be revoked
    WHEN MATCHED AND NOT EXISTS (SELECT 1 FROM temp_user_roles t 
           WHERE t.username = target.username 
           AND t.role_name = target.role_name) THEN
        UPDATE SET target.is_revoked = FALSE, target.last_sync_date = CURRENT_TIMESTAMP();
    WHEN MATCHED THEN
        UPDATE SET target.last_sync_date = CURRENT_TIMESTAMP();

    with inserted_rows as (
        SELECT 
            OBJECT_CONSTRUCT(
                'inserted rows',
                (SELECT COUNT(*) FROM ROLE_PROVISIONING where requested_date > DATEADD(seconds, -1, current_timestamp())
            ) 
        ) as result_obj
    )
    
SELECT result_obj
into :result
FROM inserted_rows;

truncate table temp_user_roles;

RETURN result;
END;
$$;