import os
import json
import google.generativeai as genai
from typing import Dict, Any

def analyze_resume_with_ai(resume_text: str, jd_text: str = "") -> Dict[str, Any]:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return {
            "strengths": ["API Key not configured"],
            "weaknesses": ["API Key not configured"],
            "suggestions": ["Add your Gemini API key to .env"],
            "project_feedback": [],
            "overall_score_reason": ""
        }
        
    genai.configure(api_key=api_key)
    
    # ─── Prompt Engineering ─────────────────────────────────────
    prompt = f"""
    You are a Senior Technical Recruiter at a FAANG company.
    
    Analyze this candidate's compatibility for the provided role:
    [RESUME TEXT START]
    {resume_text[:4000]}
    [RESUME TEXT END]
    
    Job Context (Target requirements):
    {jd_text[:1000] if jd_text else "General technical professional audit."}
    
    Return EXACTLY this JSON:
    {{
        "strengths": ["at least 3 high-impact professional strengths"],
        "weaknesses": ["at least 2 constructive career gaps"],
        "suggestions": ["3 actionable FAANG-level improvement steps"],
        "project_feedback": ["critique of project impact and complexity"],
        "overall_score_reason": "Provide a brief recruiter rationale for this hire/no-hire probability",
        "ai_score": 0-100
    }}
    
    Recruiter's Guide:
    - Score > 80: High Potential Hire (Strong experience + clear impact).
    - Score 60-80: Solid Mid-Tier (Minor gaps, but capable).
    - Score < 60: Early Career/High Gaps (Needs significant development).
    - Be brutal but helpful; ignore exact keywords, focus on impact and depth.
    """
    
    try:
        model = genai.GenerativeModel("gemini-2.5-flash")
        response = model.generate_content(
            prompt,
            generation_config={"temperature": 0.0}
        )
        
        # Parse JSON from response
        clean_text = response.text.replace("```json", "").replace("```", "").strip()
        data = json.loads(clean_text)
        return data
    except Exception as e:
        print(f"Gemini AI Error: {e}")
        return {
            "strengths": ["AI analysis failed temporarily"],
            "weaknesses": ["AI analysis failed temporarily"],
            "suggestions": ["Please check your internet connection or API key"],
            "project_feedback": [],
            "overall_score_reason": f"Error: {e}",
            "ai_score": 60
        }
