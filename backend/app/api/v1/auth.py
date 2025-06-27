from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt
import os

bearer_scheme = HTTPBearer()
SUPABASE_JWT_SECRET = os.getenv("SUPABASE_JWT")

def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme)
) -> str:
    token = credentials.credentials
    try:
        payload = jwt.decode(token, SUPABASE_JWT_SECRET, algorithms=["HS256"])
        print("JWT payload:", payload)
        return payload["sub"]
    except jwt.PyJWTError as e:
        print("JWT error:", e)
        raise HTTPException(status_code=403, detail="Invalid token")
