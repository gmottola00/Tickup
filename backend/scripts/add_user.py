import httpx
import os
from dotenv import load_dotenv
import json

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

signup_data = {
    "email": "gianmarco+1234@prova.it",
    "password": "securepassword"
}
print("Payload JSON:", json.dumps(signup_data, indent=2))

response = httpx.post(
    f"{SUPABASE_URL}/auth/v1/signup",
    headers={
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json"
    },
    json=signup_data
)

print(response.status_code)
print(response.json())
