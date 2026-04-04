import os
from typing import List, Optional
import google.generativeai as genai
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, UploadFile, File, Form, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy.orm import Session
import hashlib
import pickle
import firebase_admin
from firebase_admin import credentials, firestore as firebase_firestore

# ─── ML Model Loading ──────────────────────────────────────
MODEL_PATH = os.path.join(os.path.dirname(__file__), "ml", "model.pkl")
VECTORIZER_PATH = os.path.join(os.path.dirname(__file__), "ml", "vectorizer.pkl")

ml_model = None
ml_vectorizer = None

if os.path.exists(MODEL_PATH) and os.path.exists(VECTORIZER_PATH):
    try:
        with open(MODEL_PATH, "rb") as f:
            ml_model = pickle.load(f)
        with open(VECTORIZER_PATH, "rb") as f:
            ml_vectorizer = pickle.load(f)
        print("✅ ML Model and Vectorizer loaded successfully!")
    except Exception as e:
        print(f"❌ Error loading ML models: {e}")
else:
    print("⚠️ ML Model files not found. Prediction endpoint will be disabled.")

# Modular Imports
from ml.resume_parser import extract_skills
from ml.skill_matcher import match_skills
from ai.gemini_analyzer import analyze_resume_with_ai
from utils.file_handler import extract_text_from_file

import models
from database import engine, get_db

# Initialize Database
models.Base.metadata.create_all(bind=engine)

load_dotenv()

# ─── Firebase Admin SDK Init ──────────────────────────────
_FB_KEY = os.path.join(os.path.dirname(__file__), "serviceAccountKey.json")
if not firebase_admin._apps:
    _cred = credentials.Certificate(_FB_KEY)
    firebase_admin.initialize_app(_cred)
_db = firebase_firestore.client()

# Simple In-Memory Cache for Scoring Consistency
ANALYSIS_CACHE = {}

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

app = FastAPI(title="Prashikshan Modular Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Data Models ──────────────────────────────────────────
class FeedRequest(BaseModel):
    domains: List[str]
    limit: Optional[int] = 20

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    message: str
    session_id: str

class PredictRequest(BaseModel):
    text: str

class StudentRankRequest(BaseModel):
    domain: str = "All"
    university: str = "All"
    top_n: int = 20

# ─── ML Student Ranking Endpoints ────────────────────────
@app.post("/students/ranked")
def get_ranked_students(request: StudentRankRequest):
    try:
        docs = _db.collection("users").where("userType", "==", "student").stream()
        students = []
        for doc in docs:
            s = doc.to_dict()
            s["uid"] = doc.id
            students.append(s)

        # Filter by domain — exact string match from the domain list
        if request.domain != "All":
            students = [s for s in students if request.domain in s.get("domains", [])]
        if request.university != "All":
            students = [s for s in students if s.get("university", "") == request.university]

        # Score each student — cgpa is stored as STRING, always use try/except
        ranked = []
        for s in students:
            try:
                cgpa_val = float(s.get("cgpa", "0"))
            except (ValueError, TypeError):
                cgpa_val = 0.0
            try:
                project_score = int(s.get("projects_count", 0)) * 8
            except (ValueError, TypeError):
                project_score = 0
            cgpa_score = cgpa_val * 10
            if request.domain == "All":
                domain_bonus = 5
            elif request.domain in s.get("domains", []):
                domain_bonus = 15
            else:
                domain_bonus = 0
            total_score = cgpa_score + project_score + domain_bonus
            ranked.append({
                "uid":            s.get("uid", ""),
                "name":           s.get("name", ""),
                "university":     s.get("university", ""),
                "cgpa":           s.get("cgpa", "0"),
                "projects_count": s.get("projects_count", 0),
                "domains":        s.get("domains", []),
                "githubUrl":      s.get("githubUrl", ""),
                "linkedinUrl":    s.get("linkedinUrl", ""),
                "email":          s.get("email", ""),
                "mobileNumber":   s.get("mobileNumber", ""),
                "role":           s.get("role", ""),
                "level":          s.get("level", ""),
                "lookingFor":     s.get("lookingFor", ""),
                "score":          total_score,
            })

        ranked.sort(key=lambda x: x["score"], reverse=True)
        ranked = ranked[:request.top_n]
        for i, s in enumerate(ranked):
            s["rank"] = i + 1

        return ranked
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ranking error: {str(e)}")


@app.get("/students/universities")
def get_universities():
    try:
        docs = _db.collection("users").where("userType", "==", "student").stream()
        unis = sorted(set(
            d.to_dict().get("university", "").strip()
            for d in docs
            if d.to_dict().get("university", "").strip()
        ))
        return {"universities": unis}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error: {str(e)}")


# ─── ML Prediction Endpoint ──────────────────────────────
@app.post("/predict")
def predict_domain(request: PredictRequest):
    if not ml_model or not ml_vectorizer:
        return {"domain": "AI/ML", "error": "Model not loaded, using fallback"}

    if not request.text or len(request.text.strip()) == 0:
        return {"domain": "AI/ML", "note": "Empty text, returned default"}

    # Intelligent Behavior: Handle specific mappings
    input_text = request.text.lower().strip()
    if "data science" in input_text:
        return {"domain": "AI/ML"}

    try:
        # Transform and Predict
        vec_input = ml_vectorizer.transform([request.text])
        prediction = ml_model.predict(vec_input)[0]
        return {"domain": prediction}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")

# ─── Health Check for Mobile Debugging ───────────────────
@app.get("/health")
def health_check():
    return {
        "status": "online",
        "message": "Backend is reachable from your phone! 🚀",
        "ip_hint": "10.28.94.5"
    }

# ─── New Endpoints (Persistent Chat) ─────────────────────
@app.post("/chat/new")
def create_new_chat(db: Session = Depends(get_db)):
    new_session = models.ChatSession()
    db.add(new_session)
    db.commit()
    db.refresh(new_session)
    return {"session_id": new_session.id}

@app.get("/chat/sessions")
def get_chat_sessions(db: Session = Depends(get_db)):
    sessions = db.query(models.ChatSession).order_by(models.ChatSession.created_at.desc()).all()
    result = []
    for s in sessions:
        last_msg = db.query(models.ChatMessage).filter(models.ChatMessage.session_id == s.id).order_by(models.ChatMessage.timestamp.desc()).first()
        result.append({
            "session_id": s.id,
            "created_at": s.created_at,
            "last_message": last_msg.content if last_msg else "New conversation"
        })
    return result

@app.get("/chat/sessions/{session_id}")
def get_chat_messages(session_id: str, db: Session = Depends(get_db)):
    messages = db.query(models.ChatMessage).filter(models.ChatMessage.session_id == session_id).order_by(models.ChatMessage.timestamp.asc()).all()
    return [{"role": m.role, "content": m.content} for m in messages]

@app.post("/chat/send")
def send_message(request: ChatRequest, db: Session = Depends(get_db)):
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="Gemini API key not configured")

    # 1. Save User Message
    user_msg = models.ChatMessage(session_id=request.session_id, role="user", content=request.message)
    db.add(user_msg)
    db.commit()

    # 2. Fetch context (Last 10 messages)
    history_objs = db.query(models.ChatMessage).filter(models.ChatMessage.session_id == request.session_id).order_by(models.ChatMessage.timestamp.desc()).limit(11).all()
    history = []
    # Reverse to get chronological order
    for m in reversed(history_objs[1:]): # Skip the one we just added for history, then reverse
        # Gemini expects 'model' role instead of 'assistant'
        role = "model" if m.role == "assistant" else "user"
        history.append({"role": role, "parts": [m.content]})

    # 3. Call Gemini
    model_name = "gemini-2.5-flash"
    try:
        model = genai.GenerativeModel(
            model_name=model_name,
            system_instruction="You are Prashikshan AI, a professional career mentor. Provide concise, helpful advice for students. Use plain text only, do NOT use markdown formatting (no asterisks, no bolding, no bullet points with stars)."
        )
        chat_session = model.start_chat(history=history)
        response = chat_session.send_message(request.message)
        
        # Clean response of markdown/stars for a cleaner UI experience
        reply_text = response.text.replace("*", "").replace("`", "").strip()

        # 4. Save AI Response
        ai_msg = models.ChatMessage(session_id=request.session_id, role="assistant", content=reply_text)
        db.add(ai_msg)
        db.commit()

        return {"reply": reply_text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Gemini error: {str(e)}")

# ─── Existing Endpoints (Job Feed & Chat) ─────────────────
@app.get("/")
def home():
    return {"message": "Prashikshan Modular Backend Running 🚀"}

# ─── Modular Resume Analysis API ──────────────────────────
@app.post("/analyze-resume")
async def analyze_resume(
    resume: UploadFile = File(...),
    jd_text: str = Form("")
):
    try:
        # 1. Extract Text from File (PDF/DOCX)
        resume_text = await extract_text_from_file(resume)
        
        if not resume_text:
            raise HTTPException(status_code=400, detail="Could not extract text from the resume.")
            
        # 🧩 Deterministic Caching: Ensure same Resume/JD always give same score
        cache_key = hashlib.md5(f"{resume_text}_{jd_text}".encode()).hexdigest()
        if cache_key in ANALYSIS_CACHE:
            print(f"DEBUG: Returning cached result for {cache_key}")
            return ANALYSIS_CACHE[cache_key]

        # 2. Parse Skills from Resume
        resume_skills = extract_skills(resume_text)
        
        # 3. Match Skills against JD (Hard Matching)
        matched_skills, missing_skills, skill_match_percentage = match_skills(resume_skills, jd_text)
        
        # 4. Perform AI Qualitative Audit (Professional Insights)
        ai_data = analyze_resume_with_ai(resume_text, jd_text)
        
        # 5. Calculate Smart Score (Smarter Recruiter Refined Logics)
        # Weightage: 30% Hard Skill Match, 70% AI Qualitative Experience
        # This prevents "keyword-stuffing" penalties and rewards project quality.
        skill_score = skill_match_percentage
        ai_score = ai_data.get("ai_score", 70)
        
        # Base floor: If AI sees potential, the score shouldn't be bottomed out
        final_score = int((skill_score * 0.3) + (ai_score * 0.7))
        
        # Final sanity check: Ensure positive feedback yields a respectable score
        if ai_score > 75 and final_score < 40:
            final_score += 15 # "Potential" boost
        
        # 6. Structured Response
        result = {
            "score": final_score,
            "matched_skills": matched_skills,
            "missing_skills": missing_skills,
            "strengths": ai_data.get("strengths", []),
            "weaknesses": ai_data.get("weaknesses", []),
            "suggestions": ai_data.get("suggestions", []),
            "project_feedback": ai_data.get("project_feedback", []),
            "overall_score_reason": ai_data.get("overall_score_reason", "Analysis complete.")
        }
        
        # Save to cache
        ANALYSIS_CACHE[cache_key] = result
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")
