import json
import boto3
import snowflake.connector
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    secret_name = "snowflake_test"
    region_name = "us-west-2"

    sf_conn = get_snowflake_connection(secret_name,region_name)
    res = sf_conn.cursor().execute("SELECT CURRENT_USER();")


    return {
        'statusCode': 200,
        'body': json.dumps('Current user: {}'.fromat(res.fetchone()[0]))
    }


def get_snowflake_connection(secret_name: str, region: str, role: str = None):
    """
    Lambda function to authenticate to Snowflake using RSA private key from AWS Secrets Manager
    
    Args:
        secret_name (str): Name of the secret in AWS Secrets Manager containing the RSA private key
        region (str): AWS region where the secret is stored
        user (str): Snowflake username
        role (str, optional): Snowflake role to use
    
    Returns:
        snowflake.connector.SnowflakeConnection: Authenticated Snowflake connection
    """
    # Get the private key from Secrets Manager
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region
    )
    
    try:
        secret_value = client.get_secret_value(SecretId=secret_name)
        snowflake_private_key = secret_value['SecretString']
        user = 'domo_service_acct'
        print(user)
        
        pem_bytes = snowflake_private_key.encode('utf-8') if isinstance(snowflake_private_key, str) else snowflake_private_key
        # Load the private key
        try:
            p_key = serialization.load_pem_private_key(
                pem_bytes,
                password=None,
                backend=default_backend()
            )
        
        except Exception as e:
            raise ValueError(f"Failed to load PKCS#8 private key: {str(e)}")
        
        # Create connection parameters
        conn_params = {
            'user': user,
            'account': "SANDBOX",
            'private_key': p_key,
            'session_parameters': {
                'QUERY_TAG': 'lambda_connection'
            }
        }
        
        # Add role if provided
        if role:
            conn_params['role'] = role
            
        # Connect to Snowflake
        conn = snowflake.connector.connect(**conn_params)
        return conn
        
    except Exception as e:
        print(f"Error connecting to Snowflake: {str(e)}")
        raise