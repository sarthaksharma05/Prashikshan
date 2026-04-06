<div align="center">

<img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/FastAPI-Python_3.11-009688?style=for-the-badge&logo=fastapi&logoColor=white" />
<img src="https://img.shields.io/badge/Firebase-Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
<img src="https://img.shields.io/badge/Gemini_2.5_Flash-AI_Mentor-4285F4?style=for-the-badge&logo=google&logoColor=white" />
<img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" />

# 🎓 Prashikshan

### *An AI-Driven Ecosystem for Targeted Career Opportunities and Mentorship*

**Prashikshan** (Hindi: प्रशिक्षण — *Training / Education*) is a dual-role mobile career platform built for Indian college students and recruiters. It connects the right students to the right opportunities through domain-aware job discovery, AI-powered resume analysis, composite student ranking, and real-time application tracking.

[Research Paper](./prashikshan_research_paper.md) · [Report a Bug](https://github.com/sarthaksharma05/Prashikshan/issues) · [Request a Feature](https://github.com/sarthaksharma05/Prashikshan/issues)

</div>

---

## 📌 The Problem

India produces 1.5 million+ engineering graduates annually. Yet a large share spend months after graduation still looking for relevant work — not because there aren't enough openings, but because the tools they use to find them weren't built for them.

Generic platforms like LinkedIn and Naukri are designed for a global professional audience. For a third-year CSE student who just finished their second ML project, they're overwhelming and mostly irrelevant. Prashikshan was built to fix that.

---

## ✨ Features

### 👨‍🎓 For Students
| Feature | Description |
|---|---|
| 🔍 **Domain-Aware Job Feed** | Automatically shows jobs and hackathons matching your registered domains — no manual filtering |
| 📄 **Resume × JD Match Audit** | Upload your resume, pick a job — Gemini 2.5 Flash scores compatibility (0–100), highlights skill gaps, and gives actionable feedback |
| 🤖 **AI Career Mentor** | Persistent in-app chat mentor scoped strictly to career guidance, powered by Gemini 2.5 Flash |
| 📊 **Live Application Tracking** | Real-time status updates on every job and hackathon application |
| 🗂️ **Student Portfolio** | Showcase CGPA, projects, GitHub, LinkedIn, and career intent — feeds directly into recruiter rankings |

### 🏢 For Recruiters
| Feature | Description |
|---|---|
| 🏆 **Composite Student Ranking** | Ranked student lists based on CGPA, project count, and domain alignment — no manual browsing |
| 🎓 **By University Filter** | Drill down to specific campuses for targeted campus hiring |
| 📢 **Real-Time Notifications** | Instant alerts via Firestore WebSocket streams when students apply |
| 📝 **Job & Hackathon Posting** | Post opportunities in seconds — live in matching student feeds immediately |
| ✅ **Application Management** | Review, Accept, or Reject applicants with full profile snapshots |

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────┐
│              Flutter Client (Android)                │
│         Dart · State Management · Client-side        │
│              filtering & sorting logic               │
└──────────────┬──────────────────────┬───────────────┘
               │ HTTPS REST           │ WebSocket Stream
               ▼                      ▼
┌──────────────────────┐   ┌──────────────────────────┐
│  FastAPI Backend     │   │   Cloud Firestore (NoSQL) │
│  Python 3.11         │   │                          │
│  · Student Ranking   │   │   Users · Jobs           │
│  · LLM Proxy         │   │   Hackathons · Enrollments│
│  · Markdown Sanitise │   │   Notifications          │
└──────────┬───────────┘   └──────────────────────────┘
           │
           ▼
┌──────────────────────┐   ┌──────────────────────────┐
│  Gemini 2.5 Flash    │   │   Firebase Auth           │
│  · Career Mentor     │   │   · Email + Google SSO    │
│  · JD Match Audit    │   │   · Dual-role routing     │
│  · Response Sanitise │   │   · Session tokens        │
└──────────────────────┘   └──────────────────────────┘
```

**Why fat-client filtering?** Combining Firestore `.where()` and `.orderBy()` on different fields requires a composite index. Instead, all filtering and sorting happens on the Flutter client — delivering ~140ms feed load times and zero operational index errors.

---

## 🧮 Core Algorithm — Student Ranking

```
Score(s) = (w₁ × CGPA_s) + (w₂ × ProjectCount_s) + DomainBonus(s, d)

Default weights: w₁ = 10, w₂ = 8

DomainBonus:
  Selected domain = 'All'         → +5   (all students eligible)
  Student's domain matches filter → +15  (strong alignment rewarded)
  Student's domain doesn't match  → 0    (excluded from results)
```

> A student with 7.5 CGPA and 8 projects scores **139 pts** vs a student with 10.0 CGPA and 0 projects at **100 pts** — intentionally reflecting how technical hiring actually works.

---

## 📊 Evaluation Results (Real Firestore Data)

| Metric | Target | Result |
|---|---|---|
| Feed Relevance Precision | > 90% | **100%** across all 10 domains |
| Feed Load Time (501 jobs) | < 250 ms | **~140 ms** on Pixel 8 |
| Ranking Monotone Consistency | Always true | **Verified programmatically ✓** |
| Notification Propagation | < 100 ms | **~45 ms** via WebSocket stream |
| Enrollment Write Success | > 99% | **100%** (atomic two-document write) |

Evaluated on: **501 jobs · 50 hackathons · 24 student profiles · 36 enrollments** — all real Firestore data, no synthetic records.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Mobile Client | Flutter 3.x (Dart, Android) |
| Backend API | FastAPI (Python 3.11) |
| AI / LLM | Google Gemini 2.5 Flash |
| Database | Cloud Firestore (NoSQL) |
| Authentication | Firebase Auth (Email + Google SSO) |
| Session Management | SQLAlchemy (conversation history) |
| Testing Device | Google Pixel 8 |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x
- Python 3.11+
- Firebase project with Firestore and Authentication enabled
- Google Gemini API key

### 1. Clone the repository
```bash
git clone https://github.com/sarthaksharma05/Prashikshan.git
cd Prashikshan
```

### 2. Set up the Flutter app
```bash
cd prashikshan_app
flutter pub get
```

Add your `google-services.json` from the Firebase console into:
```
prashikshan_app/android/app/google-services.json
```

```bash
flutter run
```

### 3. Set up the FastAPI backend
```bash
cd backend
pip install -r requirements.txt
```

Create a `.env` file in the `backend/` folder:
```env
GEMINI_API_KEY=your_gemini_api_key_here
```

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

> **Note:** During development, your phone and laptop must be on the same network. Update the base URL in the Flutter app to point to your machine's local IP.

---

## 📁 Project Structure

```
Prashikshan/
├── prashikshan_app/          # Flutter Android client
│   ├── lib/
│   │   ├── screens/          # Student & company UI screens
│   │   ├── services/         # Firestore, Auth, API services
│   │   └── models/           # Data models
│   └── android/
│       └── app/
│           └── google-services.json   # Firebase config (do not commit)
├── backend/                  # FastAPI backend
│   ├── main.py               # Entry point
│   ├── .env                  # API keys (do not commit)
│   ├── routes/               # API route handlers
│   │   ├── students.py       # Ranking endpoint
│   │   ├── mentor.py         # AI chat endpoint
│   │   └── match_audit.py    # Resume × JD analysis
│   └── requirements.txt
├── prashikshan_research_paper.md  # Research paper
└── README.md
```

---

## 🗺️ Roadmap

- [ ] Jaccard skill-set matching (semantic cross-domain discovery)
- [ ] Resume PDF auto-parsing with spaCy NLP
- [ ] Google Cloud Run deployment (remove local network dependency)
- [ ] RAG-based mentor upgrade (Indian placement data corpus)
- [ ] DigiLocker API integration (verified CGPA)
- [ ] Collaborative filtering on interaction data
- [ ] Flutter Web + Desktop support

---

## 👥 Team

| Name | Role |
|---|---|
| **Sarthak Kumar Sharma** | Lead Developer — Full-stack (Flutter + FastAPI), Firebase, AI Integration, Architecture |
| **Palak Chaudhary** | Frontend Support & Research |
| **Twincy** | Research & Documentation |

📧 sarthak.sh.0515@gmail.com

---

## 📄 License

This project is for academic and educational purposes.  
© 2025 Sarthak Kumar Sharma, Palak Chaudhary & Twincy — Lovely Professional University, Punjab, India.

---
