import pandas as pd
import firebase_admin
from firebase_admin import credentials, firestore
import os

# ─── CONFIGURATION ──────────────────────────────────────────
CSV_FILE_PATH = os.path.join("data", "hackathons.csv")
SERVICE_ACCOUNT_KEY = "serviceAccountKey.json"
COLLECTION_NAME = "hackathons"

def upload_hackathons():
    print("🚀 Starting Hackathon Data Pipeline...")

    # 1. Check for Service Account Key
    if not os.path.exists(SERVICE_ACCOUNT_KEY):
        print(f"❌ Error: {SERVICE_ACCOUNT_KEY} not found in current directory.")
        return

    # 2. Initialize Firebase
    try:
        if not firebase_admin._apps:
            cred = credentials.Certificate(SERVICE_ACCOUNT_KEY)
            firebase_admin.initialize_app(cred)
        db = firestore.client()
        print("✅ Firebase initialized successfully.")
    except Exception as e:
        print(f"❌ Firebase connection failure: {e}")
        return

    # 3. Read CSV File
    if not os.path.exists(CSV_FILE_PATH):
        print(f"❌ Error: {CSV_FILE_PATH} not found.")
        return

    try:
        df = pd.read_csv(CSV_FILE_PATH)
        total_rows = len(df)
        print(f"📊 Read {total_rows} rows from CSV.")
    except Exception as e:
        print(f"❌ Error reading CSV: {e}")
        return

    # 4. Upload to Firestore
    success_count = 0
    fail_count = 0

    for index, row in df.iterrows():
        # Validation: Skip rows with missing title or company
        if pd.isna(row.get('title')) or pd.isna(row.get('company')):
            print(f"⚠️ Skipping row {index+1}: Missing required fields (title/company).")
            fail_count += 1
            continue

        try:
            # Convert row to clean dictionary
            hackathon_data = {
                "id": int(row['id']) if not pd.isna(row['id']) else index + 1,
                "title": str(row['title']).strip(),
                "company": str(row['company']).strip(),
                "location": str(row['location']).strip() if not pd.isna(row['location']) else "Remote",
                "mode": str(row['mode']).strip() if not pd.isna(row['mode']) else "Online",
                "prize": str(row['prize']).strip() if not pd.isna(row['prize']) else "TBD",
                "deadline": str(row['deadline']).strip() if not pd.isna(row['deadline']) else "N/A",
                "description": str(row['description']).strip() if not pd.isna(row['description']) else "",
                "domain": str(row['domain']).strip() if not pd.isna(row['domain']) else "General",
                "registration_link": str(row['registration_link']).strip() if not pd.isna(row['registration_link']) else "#"
            }

            # Use ID as document ID for overwriting/idempotency
            doc_id = str(hackathon_data["id"])
            db.collection(COLLECTION_NAME).document(doc_id).set(hackathon_data)
            
            success_count += 1
            print(f"✅ [{success_count}/{total_rows}] Uploaded: {hackathon_data['title']}")

        except Exception as e:
            print(f"❌ Failed to upload row {index+1}: {e}")
            fail_count += 1

    # 5. Final Report
    print("\n" + "="*40)
    print("🏁 DATA UPLOAD COMPLETE")
    print(f"📈 Total records read:   {total_rows}")
    print(f"✅ Successfully uploaded: {success_count}")
    print(f"❌ Failed records:       {fail_count}")
    print("="*40)

if __name__ == "__main__":
    upload_hackathons()
