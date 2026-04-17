# Schemas
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime

from pydantic import BaseModel
from database import User

from routers.auth import hash_password
from routers.savings import get_db

router = APIRouter()

# Schema
class UserCreate(BaseModel):
    name: str
    username: str
    password: str

class UserResponse(BaseModel):
    id: int
    name: str
    username: str
    created_at: datetime

# Endpoints
@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def create_user(body: UserCreate, db: Session = Depends(get_db)):
    # Check if username already exists
    existing = db.query(User).filter(User.username == body.username).first()
    if existing:
        raise HTTPException(status_code=400, detail="Username already exists")
    
    print("password", body.password)

    user = User(
        name=body.name,
        username=body.username,
        hashed_password=hash_password(body.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user