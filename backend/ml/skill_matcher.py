from typing import List, Tuple

def match_skills(resume_skills: List[str], jd_text: str) -> Tuple[List[str], List[str], int]:
    jd_text = jd_text.lower()
    
    # Simple keyword extraction from JD (can be improved)
    # For now, we'll just check our known skill list against the JD
    from ml.resume_parser import ALL_RECOGNIZED_SKILLS, SKILL_NORMALIZATION
    
    jd_required_skills = set()
    for skill in ALL_RECOGNIZED_SKILLS:
        if skill in jd_text:
            normalized = SKILL_NORMALIZATION.get(skill, skill.title())
            jd_required_skills.add(normalized)
            
    # Calculate matches
    resume_skills_set = set(resume_skills)
    matched_skills = sorted(list(resume_skills_set.intersection(jd_required_skills)))
    missing_skills = sorted(list(jd_required_skills.difference(resume_skills_set)))
    
    # Calculate match percentage
    if not jd_required_skills:
        return matched_skills, missing_skills, 100
        
    match_percentage = int((len(matched_skills) / len(jd_required_skills)) * 100)
    
    return matched_skills, missing_skills, match_percentage
