# Snowflake Provisioning

This repo contains the code for provisioning users and roles in Snowflake.

## Example Usage

1. Add a user-role combination to `user_roles.json`:

```
{"username": "STRIBBY.GREYDUCK@STARTRIBUNE.COM", "role": "FR_DEV_DATAENGINEER"}
```

2. Create a pull request and merge it into the main branch.

3. The workflow will run and provision the user and role.

4. The workflow will also revoke any roles that are no longer in the `user_roles.json` file.
