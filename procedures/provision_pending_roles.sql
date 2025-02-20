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
    var roles_revoked = 0;
    var errors = [];

    console.log("Pending roles: " + pending_roles.getRowCount());
    
    // Process each pending role
    if (pending_roles.getRowCount()>0){
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
    }

    // Get pending role revokes
    var pending_revokes = snowflake.createStatement({
        sqlText: `
            SELECT username, role_name 
            FROM ROLE_PROVISIONING 
            WHERE is_revoked = TRUE
            and revoked_date is NULL;
        `
    }).execute();

    console.log("Pending revokes: " + pending_revokes.getRowCount());

    // Process each pending revoke
    if (pending_revokes.getRowCount()>0){
        while (pending_revokes.next()) {
            var username = pending_revokes.getColumnValue(1);
            var role_name = pending_revokes.getColumnValue(2);
            
            console.log(`Processing revoke: ${role_name} from ${username}`);
            
            try {
                // Double quote the username for email addresses
                var revoke_stmt = snowflake.createStatement({
                    sqlText: `REVOKE ROLE IDENTIFIER(?) FROM USER "${username}"`,
                    binds: [role_name]
                }).execute();

                // Update the provisioning status using binds
                var update_stmt_revoke = snowflake.createStatement({
                    sqlText: `
                        UPDATE ROLE_PROVISIONING 
                        SET 
                            is_revoked = TRUE,
                            revoked_date = CURRENT_TIMESTAMP(),
                            last_sync_date = CURRENT_TIMESTAMP()
                        WHERE username = ?
                        AND role_name = ?
                    `,
                    binds: [username, role_name]
                }).execute();
                
                roles_revoked++;
                
            } catch (grant_error) {
                // Log any errors that occur during revoking
                errors.push(`Error revoking ${role_name} from ${username}: ${grant_error.message}`);
            }
        }
    }
    
    
    // Prepare result message
    var result = `Processed ${roles_granted} role grants and ${roles_revoked} role revokes`;
    if (errors.length > 0) {
        result += ` Encountered ${errors.length} errors:\n${errors.join('\n')}`;
    }
    
    return result;
    
} catch (error) {
    return `Error in procedure execution: ${error.message}`;
}
$$;