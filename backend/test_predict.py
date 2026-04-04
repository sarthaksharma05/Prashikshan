import requests

url = "http://127.0.0.1:8000/predict"
payload = {"text": "Data Science Intern"}

try:
    response = requests.post(url, json=payload)
    print(f"Status Code: {response.statusCode}")
    print(f"Response: {response.json()}")
except Exception as e:
    print(f"Error: {e}")
