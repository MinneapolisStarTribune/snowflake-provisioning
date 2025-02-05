CREATE OR REPLACE PROCEDURE INSERT_USER_ROLE(
    p_username VARCHAR(255),
    p_role_name VARCHAR(255)
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
DECLARE
    v_result VARCHAR;
    v_quoted_username VARCHAR;
BEGIN
    -- Ensure username (email) is properly quoted
    v_quoted_username := CONCAT('"', p_username, '"');

    -- Attempt to insert the new user role record
    BEGIN
        INSERT INTO ROLE_PROVISIONING (
            username, 
            role_name, 
            is_provisioned, 
            requested_date
        )
        VALUES (
            :v_quoted_username, 
            :p_role_name, 
            FALSE, 
            CURRENT_TIMESTAMP()
        );
        
        v_result := 'User role record inserted successfully.';
        RETURN v_result;
    
    EXCEPTION
        -- Handle potential duplicate key violation
        WHEN UNIQUE_KEY_VIOLATION THEN
            v_result := 'Error: User role combination already exists.';
            RETURN v_result;
        
        -- Handle other potential errors
        WHEN OTHER THEN
            v_result := 'Error: ' || SQLERRM;
            RETURN v_result;
    END;
END;
$$;

-- Example usage:
-- CALL INSERT_USER_ROLE('john.doe@example.com', 'DATA_ANALYST');