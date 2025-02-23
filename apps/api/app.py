import os
import logging
import psycopg2
from flask import Flask, jsonify

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Cloud SQL connection details
DB_USER = os.getenv("DB_USER")
DB_PASS = os.getenv("DB_PASS")
DB_NAME = os.getenv("DB_NAME")
DB_HOST = os.getenv("DB_HOST")  # Use instance private IP

def get_db_connection():
    """Creates a connection to the Cloud SQL database"""
    try:
        logger.info("Connecting to database: %s on host: %s", DB_NAME, DB_HOST)
        conn = psycopg2.connect(
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASS,
            host=DB_HOST
        )
        logger.info("Database connection established successfully.")
        return conn
    except Exception as e:
        logger.error("Database connection failed: %s", str(e))
        raise

@app.route("/data", methods=["GET"])
def get_data():
    """Fetches data from the database"""
    logger.info("Received request: GET /data")
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM my_table LIMIT 10;")
        rows = cursor.fetchall()
        conn.close()
        
        logger.info("Fetched %d records from database.", len(rows))
        return jsonify([{"id": row[0], "name": row[1]} for row in rows])
    except Exception as e:
        logger.error("Error fetching data: %s", str(e))
        return jsonify({"error": "Failed to fetch data"}), 500

@app.route("/", methods=["GET"])
def health_check():
    logger.info("Health check: GET /")
    return "Cloud Run App is running! Test", 200

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    logger.info("Starting Flask app on port %d", port)
    app.run(host="0.0.0.0", port=port)
