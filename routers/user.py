# Schemas
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime

from pydantic import BaseModel
from database import User, Saving, get_db

from routers.auth import hash_password, get_current_user

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

class UserUpdate(BaseModel):
    id: int | None
    name: str | None
    username: str | None
    created_at: datetime | None

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

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user

@router.put("/me", response_model=UserResponse)
def update_me(
    body: UserUpdate, 
    current_user: User = Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    updates = body.model_dump(exclude_unset=True)

    if "username" in updates:
        existing = db.query(User).filter(User.username == updates["username"]).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already in use"
            )

    for key, value in updates.items():
        setattr(current_user, key, value)

    db.commit()
    db.refresh(current_user)
    return current_user

@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
def delete_me(
    current_user: User = Depends(get_current_user), 
    db: Session = Depends(get_db)
):
    # Delete current user's savings
    db.query(Saving).filter(Saving.user_id == current_user.id).delete()

    db.delete(current_user)
    db.commit()
    return