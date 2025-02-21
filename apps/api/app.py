from flask import Flask, jsonify
import os
import pymysql
import logging
from google.cloud import secretmanager

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

app = Flask(__name__)

def get_secret(secret_name):
    """Fetch secret value from Secret Manager1"""
    project_id = os.getenv("GCP_PROJECT_ID", "your-project-id")
    secret_path = f"projects/{project_id}/secrets/db_admin_password/versions/latest"

    try:
        logger.info(f"Fetching secret: {secret_name} from Secret Manager")
        client = secretmanager.SecretManagerServiceClient()
        response = client.access_secret_version(name=secret_path)
        secret_value = response.payload.data.decode("UTF-8")
        logger.info(f"Successfully retrieved secret: {secret_name}")
        return secret_value
    except Exception as e:
        logger.error(f"Error fetching secret {secret_name}: {e}")
        return None  # Avoid crashing

# Get Cloud SQL connection details
DB_USER = os.getenv("DB_USER", "root")
DB_PASS = get_secret("DB_PASS")  # Fetch password from Secret Manager
DB_NAME = os.getenv("DB_NAME", "mydatabase")
DB_HOST = os.getenv("DB_HOST", "127.0.0.1")  # Change to your Cloud SQL host

def get_db_connection():
    """Establishes connection to Cloud SQL"""
    try:
        logger.info(f"Connecting to database {DB_NAME} on host {DB_HOST} as user {DB_USER}")
        connection = pymysql.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASS,
            database=DB_NAME,
            cursorclass=pymysql.cursors.DictCursor
        )
        logger.info("Database connection successful")
        return connection
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        return None

@app.route('/')
def home():
    logger.info("Received request on /")
    return "Welcome to the Cloud SQL + Cloud Run API!"

@app.route('/data', methods=['GET'])
def get_data():
    """Fetches data from the database"""
    logger.info("Received request on /data")
    connection = get_db_connection()
    if connection is None:
        logger.error("Database connection not established")
        return jsonify({"error": "Database connection failed"}), 500

    try:
        with connection.cursor() as cursor:
            logger.info("Executing SQL query: SELECT * FROM my_table LIMIT 10;")
            cursor.execute("SELECT * FROM my_table LIMIT 10;")
            result = cursor.fetchall()
            logger.info(f"Query successful, retrieved {len(result)} records")
        return jsonify(result)
    except Exception as e:
        logger.error(f"Error executing query: {e}")
        return jsonify({"error": str(e)}), 500
    finally:
        connection.close()
        logger.info("Database connection closed")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
