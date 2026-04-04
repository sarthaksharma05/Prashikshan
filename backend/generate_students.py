import csv
import random
import os

# ─── CONFIGURATION ──────────────────────────────────────────
OUTPUT_FILE = os.path.join("data", "students.csv")
TOTAL_RECORDS = 100

UNIVERSITIES = [
    "Lovely Professional University", "Chandigarh University", "Amity University",
    "Delhi University", "IIT Delhi", "BITS Pilani", "SRM University",
    "VIT Vellore", "NIT Trichy", "IIIT Hyderabad", "IIT Bombay", "IIT Madras"
]

DOMAINS = [
    "AI/ML", "Web Development", "Android Development", "UI/UX Design",
    "Backend Development", "Data Engineering", "Cloud & DevOps",
    "Cybersecurity", "Blockchain", "Game Development"
]

NAMES = [
    "Arjun", "Aditi", "Rohan", "Sanya", "Vikram", "Neha", "Ishaan", "Priya",
    "Aravind", "Kavya", "Rahul", "Ananya", "Siddharth", "Meera", "Karan",
    "Sneha", "Varun", "Riya", "Manish", "Pooja", "Aman", "Tanvi", "Suresh",
    "Deepika", "Kartik", "Shreya", "Akash", "Swati", "Harsh", "Divya"
]

SURNAMES = [
    "Sharma", "Verma", "Gupta", "Singh", "Patel", "Reddy", "Iyer", "Nair",
    "Joshi", "Kapoor", "Mehta", "Bose", "Chawla", "Malhotra", "Das", "Rao"
]

def generate_students():
    print("🚀 Initializing Student Data Generator...")
    
    # Ensure data directory exists
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)

    records = []
    
    for i in range(1, TOTAL_RECORDS + 1):
        stu_id = f"stu{i}"
        first_name = random.choice(NAMES)
        last_name = random.choice(SURNAMES)
        full_name = f"{first_name} {last_name}"
        email = f"{first_name.lower()}.{last_name.lower()}{i}@example.com"
        phone = f"{random.randint(700, 999)}{random.randint(1000000, 9999999)}"
        university = random.choice(UNIVERSITIES)
        projects = random.randint(3, 12)
        cgpa = round(random.uniform(7.5, 9.8), 2)
        domain = random.choice(DOMAINS)
        github = f"https://github.com/user{i}"
        linkedin = f"https://linkedin.com/in/user{i}"
        
        record = {
            "id": stu_id,
            "name": full_name,
            "email": email,
            "phone": phone,
            "university": university,
            "projects": projects,
            "cgpa": cgpa,
            "domain": domain,
            "github": github,
            "linkedin": linkedin,
            "role": "student"
        }
        records.append(record)

    # Write to CSV
    try:
        with open(OUTPUT_FILE, mode='w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=records[0].keys())
            writer.writeheader()
            writer.writerows(records)
        
        print(f"✅ CSV generated successfully at: {OUTPUT_FILE}")
        print(f"📈 Total records count: {len(records)}")
        
        # Preview first 3 rows
        print("\n📝 First 3 rows preview:")
        print("-" * 40)
        for r in records[:3]:
            print(f"ID: {r['id']} | Name: {r['name']} | University: {r['university']} | CGPA: {r['cgpa']}")
        print("-" * 40)

    except Exception as e:
        print(f"❌ Error writing CSV: {e}")

if __name__ == "__main__":
    generate_students()
