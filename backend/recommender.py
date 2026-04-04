from math import log
from pathlib import Path
import pandas as pd

BASE_DIR = Path(__file__).resolve().parent
jobs = pd.read_csv(BASE_DIR / "data" / "job_postings.csv")
skills = pd.read_csv(BASE_DIR / "data" / "job_skills.csv")

# New dataset already has 'skill' column with English names
# No renaming needed

def calculate_idf(skills_df):
    skill_counts = skills_df.groupby("skill")["job_id"].nunique()
    total_jobs = len(skills_df["job_id"].unique())
    idf = {}
    for skill, count in skill_counts.items():
        idf[str(skill).lower()] = log(total_jobs / (1 + count))
    return idf

def recommend_jobs(user_skills: list[str]) -> list[dict]:
    normalized_user_skills = {s.lower().strip() for s in user_skills}
    idf = calculate_idf(skills)

    job_scores = {}
    job_match_count = {}

    for _, row in skills.iterrows():
        job_id = row["job_id"]
        job_skill = str(row["skill"]).lower().strip()

        # Match if user skill is contained in job skill or vice versa
        matched = any(
            user_skill in job_skill or job_skill in user_skill
            for user_skill in normalized_user_skills
        )

        if matched:
            score = idf.get(job_skill, 0)
            job_scores[job_id] = job_scores.get(job_id, 0) + score
            job_match_count[job_id] = job_match_count.get(job_id, 0) + 1

    filtered_scores = {
        job_id: score
        for job_id, score in job_scores.items()
        if job_match_count.get(job_id, 0) >= 1
    }

    sorted_jobs = sorted(filtered_scores.items(), key=lambda x: x[1], reverse=True)
    top_job_ids = [job_id for job_id, _ in sorted_jobs[:10]]

    jobs_by_id = jobs.set_index("job_id")
    recommendations = []

    for job_id in top_job_ids:
        if job_id not in jobs_by_id.index:
            continue
        job = jobs_by_id.loc[job_id]
        title = str(job.get("title", "") or "")
        company = str(job.get("company", "") or "")
        location = str(job.get("location", "") or "")
        domain = str(job.get("domain", "") or "")
        if pd.isna(job.get("title")):
            title = ""
        recommendations.append({
            "job_id": int(job_id),
            "title": title,
            "company": company,
            "location": location,
            "domain": domain,
        })

    return recommendations
