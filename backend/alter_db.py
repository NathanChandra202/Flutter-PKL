import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

user = os.getenv("POSTGRES_USER", "devduaenam")
password = os.getenv("POSTGRES_PASSWORD", "dev26sep")
host = os.getenv("POSTGRES_SERVER", "100.120.192.13")
port = os.getenv("POSTGRES_PORT", "5432")
dbname = os.getenv("POSTGRES_DB", "kostraktor_id")

conn_string = f"dbname='{dbname}' user='{user}' host='{host}' password='{password}' port='{port}'"

queries = [
    # Existing columns (will be skipped if already present)
    "ALTER TABLE bookings ADD COLUMN ktp_image_url VARCHAR NULL;",
    "ALTER TABLE bookings ADD COLUMN selfie_image_url VARCHAR NULL;",
    "ALTER TABLE bookings ADD COLUMN bukti_bayar_url VARCHAR NULL;",
    "ALTER TABLE bookings ADD COLUMN referensi_transaksi VARCHAR NULL;",
    # New: track active room per user
    "ALTER TABLE users ADD COLUMN current_room_id INTEGER NULL REFERENCES kost_rooms(id) ON DELETE SET NULL;",
    # New: support admin-entered custom reviewer name
    "ALTER TABLE reviews ADD COLUMN manual_reviewer_name VARCHAR NULL;",
]

print("Connecting to database...")
try:
    conn = psycopg2.connect(conn_string)
    conn.autocommit = True
    cursor = conn.cursor()
    
    for query in queries:
        try:
            print(f"Executing: {query}")
            cursor.execute(query)
            print("Success.")
        except psycopg2.errors.DuplicateColumn as e:
            print(f"Column already exists (skipping): {e}")
        except Exception as e:
            print(f"Error executing query: {e}")
            
    cursor.close()
    conn.close()
    print("\nDatabase alteration completed.")
except Exception as e:
    print(f"Failed to connect or execute: {e}")
