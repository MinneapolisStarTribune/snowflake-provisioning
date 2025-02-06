use database PROVISIONING_DB;
use schema users;
CREATE OR REPLACE PROCEDURE PROVISION_PENDING_ROLES()
RETURNS STRING
LANGUAGE JAVASCRIPT
EXECUTE AS OWNER
AS
$$
try {
    // Get pending role assignments
    var pending_roles = snowflake.createStatement({
        sqlText: `
            SELECT username, role_name 
            FROM ROLE_PROVISIONING 
            WHERE is_provisioned = FALSE
        `
    }).execute();
    
    var roles_granted = 0;
    var errors = [];
    
    // Process each pending role
    while (pending_roles.next()) {
        var username = pending_roles.getColumnValue(1);
        var role_name = pending_roles.getColumnValue(2);
        
        try {
            // Double quote the username for email addresses
            var grant_stmt = snowflake.createStatement({
                sqlText: `GRANT ROLE IDENTIFIER(?) TO USER "${username}"`,
                binds: [role_name]
            }).execute();
            
            // Update the provisioning status using binds
            var update_stmt = snowflake.createStatement({
                sqlText: `
                    UPDATE ROLE_PROVISIONING 
                    SET 
                        is_provisioned = TRUE,
                        provisioned_date = CURRENT_TIMESTAMP(),
                        last_sync_date = CURRENT_TIMESTAMP()
                    WHERE username = ?
                    AND role_name = ?
                `,
                binds: [username, role_name]
            }).execute();
            
            roles_granted++;
            
        } catch (grant_error) {
            // Log any errors that occur during granting
            errors.push(`Error granting ${role_name} to ${username}: ${grant_error.message}`);
        }
    }
    
    // Prepare result message
    var result = `Processed ${roles_granted} role grants.`;
    if (errors.length > 0) {
        result += ` Encountered ${errors.length} errors:\n${errors.join('\n')}`;
    }
    
    return result;
    
} catch (error) {
    return `Error in procedure execution: ${error.message}`;
}
$$;