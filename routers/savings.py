from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import func
from database import Saving, SessionLocal, User, get_db
from sqlalchemy.orm import Session
from datetime import datetime
from database import Currency
from routers.user import get_current_user

router = APIRouter()

# Schema
class SavingCreate(BaseModel):
    amount: float
    currency: Currency
    description: str | None = None
    date: datetime = datetime.now()

class SavingUpdate(BaseModel):
    amount: float | None = None
    currency: Currency | None = None
    description: str | None = None
    date: datetime | None = None

class SavingResponse(BaseModel):
    id: int
    amount: float
    currency: Currency
    description: str | None = None
    date: datetime
    created_at: datetime

    class Config:
        from_attributes = True

class SavingTotalResponse(BaseModel):
    total: float

# Endpoints
@router.get("/", response_model=list[SavingResponse])
def get_savings(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return db.query(Saving).filter(Saving.user_id == user.id).all()

@router.get("/total", response_model=SavingTotalResponse)
def get_saving_total(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    total = db.query(Saving).filter(Saving.user_id == user.id).with_entities(func.sum(Saving.amount)).scalar() or 0.0
    return SavingTotalResponse(total=total)

@router.get("/this-month", response_model=SavingTotalResponse)
def get_savings_this_month(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    now = datetime.now()
    current_month = f"{now.month:02d}"
    current_year = str(now.year)
    saved_this_month = (
        db.query(Saving)
        .filter(
            Saving.user_id == user.id,
            func.strftime("%m", Saving.created_at) == current_month,
            func.strftime("%Y", Saving.created_at) == current_year,
        )
        .with_entities(func.sum(Saving.amount))
        .scalar()
    ) or 0.0
    return SavingTotalResponse(total=saved_this_month)

@router.post("/", response_model=SavingResponse)
def add_saving(body: SavingCreate, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    saving = Saving(
        user_id=user.id,
        amount=body.amount,
        currency=body.currency,
        description=body.description,
        date=body.date or datetime.now(),
    )
    db.add(saving)
    db.commit()
    db.refresh(saving)
    return saving

@router.delete("/")
def delete_all_savings(db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    db.query(Saving).filter(Saving.user_id == user.id).delete()
    db.commit()
    return {"ok": True}

@router.get("/{saving_id}", response_model=SavingResponse)
def get_saving(saving_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)):
    return db.query(Saving).filter(Saving.id == saving_id, Saving.user_id == user.id).first()

@router.delete("/{saving_id}")
def delete_saving(saving_id: int, db: Session = Depends(get_db), user = Depends(get_current_user)):
    saving = db.query(Saving).filter(Saving.id == saving_id, Saving.user_id == user.id).first()
    if not saving:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Saving not found"
        )
    db.delete(saving)
    db.commit()
    return {"ok": True}

@router.put("/{saving_id}")
def update_saving(
    body: SavingUpdate, 
    saving_id: int, 
    db: Session = Depends(get_db), 
    user = Depends(get_current_user)
):
    saving = db.query(Saving).filter(Saving.id == saving_id, Saving.user_id == user.id).first()
    if not saving:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Saving not found"
        )
    
    updates = body.model_dump(exclude_unset=True)

    for key, value in updates.items():
        setattr(saving, key, value)

    db.commit()
    db.refresh(saving)
    return saving