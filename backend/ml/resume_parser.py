import re
from typing import List, Set

# Professional Skill Dictionary (Expanded)
ALL_RECOGNIZED_SKILLS = set([
    # Programming Languages
    "python", "javascript", "java", "c++", "c#", "ruby", "go", "kotlin", "swift", "dart", "php", "r", "typescript",
    # Web Frameworks
    "flutter", "android", "react", "angular", "vue", "node.js", "express", "fastapi", "django", "flask", "next.js", "tailwind css", "bootstrap",
    # Databases
    "sql", "nosql", "postgresql", "mongodb", "redis", "mysql", "sqlite", "oracle", "firebase",
    # Cloud & DevOps
    "docker", "kubernetes", "aws", "azure", "gcp", "git", "github", "ci/cd", "jenkins", "terraform", "ansible", "linux", "cloud computing",
    # AI & Data Science
    "machine learning", "deep learning", "ai", "nlp", "computer vision", "pandas", "numpy", "pytorch", "tensorflow", "scikit-learn", "data science", "data analysis",
    # Design & Tools
    "ui design", "ux design", "figma", "testing", "unit testing", "rest api", "graphql", "microservices"
])

# Skill Normalization Mapping
SKILL_NORMALIZATION = {
    "py": "Python",
    "python": "Python",
    "js": "JavaScript",
    "javascript": "JavaScript",
    "reactjs": "React",
    "react": "React",
    "node": "Node.js",
    "node.js": "Node.js",
    "flutter": "Flutter",
    "dart": "Dart",
    # Add more as needed
}

def extract_skills(text: str) -> List[str]:
    text = text.lower()
    found_skills = set()
    
    for skill in ALL_RECOGNIZED_SKILLS:
        # Match whole words only
        if re.search(rf"\b{re.escape(skill)}\b", text):
            # Normalize if mapping exists, otherwise capitalize
            normalized = SKILL_NORMALIZATION.get(skill, skill.title())
            found_skills.add(normalized)
            
    return sorted(list(found_skills))
