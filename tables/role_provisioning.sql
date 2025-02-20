use database provisioning_db;
use schema users;

CREATE TABLE ROLE_PROVISIONING (
    username VARCHAR(255) NOT NULL,
    role_name VARCHAR(255) NOT NULL,
    is_provisioned BOOLEAN DEFAULT FALSE,
    requested_date TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    provisioned_date TIMESTAMP_LTZ,
    is_revoked BOOLEAN DEFAULT FALSE,
    revoked_date TIMESTAMP_LTZ,
    last_sync_date TIMESTAMP_LTZ,
    PRIMARY KEY (username, role_name)
);