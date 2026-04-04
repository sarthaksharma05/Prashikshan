import pandas as pd
import firebase_admin
from firebase_admin import credentials, firestore
import os

# ─── CONFIGURATION ──────────────────────────────────────────
CSV_FILE_PATH = os.path.join("data", "students.csv")
SERVICE_ACCOUNT_KEY = "serviceAccountKey.json"
COLLECTION_NAME = "users"

def upload_students():
    print("🚀 Starting Student Data Upload to Firebase...")

    # 1. Check for Service Account Key
    if not os.path.exists(SERVICE_ACCOUNT_KEY):
        print(f"❌ Error: {SERVICE_ACCOUNT_KEY} not found.")
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
        # Validation: Skip rows with missing name or email
        if pd.isna(row.get('name')) or pd.isna(row.get('email')):
            print(f"⚠️ Skipping row {index+1}: Missing name or email.")
            fail_count += 1
            continue

        try:
            # Map CSV fields to App User Model
            # Note: We use 'id' as the document ID (stu1, stu2, etc.)
            user_data = {
                "uid": str(row['id']),
                "name": str(row['name']).strip(),
                "email": str(row['email']).strip(),
                "mobileNumber": str(row['phone']).strip(),
                "university": str(row['university']).strip(),
                "projects_count": int(row['projects']), # Helper field
                "projects": [], # Initialize empty projects list
                "cgpa": str(row['cgpa']),
                "role": "Software Engineer", # Default target role
                "domains": [str(row['domain']).strip()],
                "level": "Student",
                "lookingFor": "Internships",
                "githubUrl": str(row['github']).strip(),
                "linkedinUrl": str(row['linkedin']).strip(),
                "isOnboarded": True,
                "createdAt": firestore.SERVER_TIMESTAMP,
                "userType": "student"
            }

            doc_id = user_data["uid"]
            db.collection(COLLECTION_NAME).document(doc_id).set(user_data)
            
            success_count += 1
            if success_count % 10 == 0:
                print(f"⏳ Processed {success_count}/{total_rows} students...")

        except Exception as e:
            print(f"❌ Failed to upload row {index+1} ({row.get('name')}): {e}")
            fail_count += 1

    # 5. Final Report
    print("\n" + "="*40)
    print("🏁 STUDENT UPLOAD COMPLETE")
    print(f"📈 Total records read:   {total_rows}")
    print(f"✅ Successfully uploaded: {success_count}")
    print(f"❌ Failed records:       {fail_count}")
    print("="*40)

if __name__ == "__main__":
    upload_students()
