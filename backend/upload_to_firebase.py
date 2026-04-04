import csv
import json
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent

# Read CSVs
jobs = {}
with open(BASE_DIR / "data" / "job_postings.csv", encoding="utf-8") as f:
    for row in csv.DictReader(f):
        jobs[row["job_id"]] = {
            "job_id": int(row["job_id"]),
            "title": row["title"],
            "company": row["company"],
            "location": row["location"],
            "domain": row["domain"],
            "skills": []
        }

with open(BASE_DIR / "data" / "job_skills.csv", encoding="utf-8") as f:
    for row in csv.DictReader(f):
        if row["job_id"] in jobs:
            jobs[row["job_id"]]["skills"].append(row["skill"])

# Export as JSON for Firebase import
job_list = list(jobs.values())
with open(BASE_DIR / "data" / "jobs_firebase.json", "w", encoding="utf-8") as f:
    json.dump(job_list, f, indent=2)

print(f"Exported {len(job_list)} jobs to data/jobs_firebase.json")
print("Sample:", job_list[0])
