import pandas as pd
import pickle
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score
import os

# 1. Load Dataset
print("🚀 Loading dataset...")
file_path = os.path.join(os.path.dirname(__file__), "..", "data", "job_postings.csv")
df = pd.read_csv(file_path)

# 2. Preprocess
# Use 'title' as input and 'domain' as label
X = df['title']
y = df['domain']

# 3. Train-Test Split (80-20)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# 4. Vectorization (TF-IDF)
print("📦 Vectorizing text...")
vectorizer = TfidfVectorizer(stop_words='english', lowercase=True)
X_train_vec = vectorizer.fit_transform(X_train)
X_test_vec = vectorizer.transform(X_test)

# 5. Train Model (Logistic Regression)
print("🧠 Training Logistic Regression model...")
model = LogisticRegression(max_iter=1000)
model.fit(X_train_vec, y_train)

# 6. Evaluation
y_pred = model.predict(X_test_vec)
accuracy = accuracy_score(y_test, y_pred)
print(f"✅ Training Complete! Accuracy: {accuracy:.2f}")

# 7. Save Model & Vectorizer
# Ensure ml directory exists
os.makedirs(os.path.dirname(__file__), exist_ok=True)

with open(os.path.join(os.path.dirname(__file__), "model.pkl"), "wb") as f:
    pickle.dump(model, f)

with open(os.path.join(os.path.dirname(__file__), "vectorizer.pkl"), "wb") as f:
    pickle.dump(vectorizer, f)

print(f"💾 Files saved: model.pkl, vectorizer.pkl")
