import json
import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent

cred = credentials.Certificate(BASE_DIR / "serviceAccountKey.json")
firebase_admin.initialize_app(cred)

db = firestore.client()

with open(BASE_DIR / "data" / "jobs_firebase.json", encoding="utf-8") as f:
    jobs = json.load(f)

batch = db.batch()
count = 0

for job in jobs:
    doc_ref = db.collection("jobs").document(str(job["job_id"]))
    batch.set(doc_ref, job)
    count += 1
    if count % 499 == 0:
        batch.commit()
        batch = db.batch()
        print(f"Committed {count} jobs...")

batch.commit()
print(f"Successfully imported {count} jobs to Firestore!")