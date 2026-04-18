from datetime import datetime, timedelta, UTC

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from passlib.context import CryptContext
from pydantic import BaseModel
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from database import SessionLocal, User, get_db
from config import settings

router = APIRouter()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

# Schemas
class Token(BaseModel):
    access_token: str
    token_type: str

# Helpers
def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: dict) -> str:
    # JWT token contains sub, subject, and exp, expiration time
    # Data we pass in already has sub (user_id), so we just need to add the exp field
    to_encode = data.copy()
    expire = datetime.now(UTC) + timedelta(minutes=settings.access_token_expire_minutes)
    to_encode.update({"exp": expire})
    
    return jwt.encode(to_encode, settings.secret_key, algorithm=settings.algorithm)

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=401,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(
            token=token, 
            key=settings.secret_key, 
            algorithms=[settings.algorithm]
        )

        user_id: int | None = payload.get("sub")

        if user_id is None:
            print("None")
            raise credentials_exception
        
    except JWTError as err:
        raise credentials_exception
    
    user = db.query(User).filter(User.id == int(user_id)).first()
    if user is None:
        raise credentials_exception
    return user

@router.post("/login", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user: User | None = db.query(User).filter(User.username == form_data.username).first()

    # Return a JWT token only if the user has provided correct username+password
    if not user or not verify_password(form_data.password, user.hashed_password): #type: ignore
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
        ) 
    
    token = create_access_token({"sub": str(user.id)})
    return Token(access_token=token, token_type="bearer")