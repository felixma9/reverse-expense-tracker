from datetime import datetime, UTC
from enum import StrEnum

from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, String, Enum as SQLEnum, create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship, sessionmaker

from backend.config import settings

engine = create_engine(
    url=settings.database_url, 
    connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(
    bind=engine, 
    autocommit=False, 
    autoflush=False
)
Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)
    username = Column(String, unique=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.now(UTC))
    savings = relationship("Saving", back_populates="user")
    
class Currency(StrEnum):
    CAD = "CAD"
    USD = "USD"
    EUR = "EUR"
    JPY = "JPY"

class Saving(Base):
    __tablename__ = "savings"
    id = Column(
        Integer, 
        primary_key=True,
    )
    user_id = Column(
        Integer, 
        ForeignKey("users.id"), 
        nullable=False
    )
    amount = Column(
        Float, 
        nullable=False
    )
    currency = Column(
        SQLEnum(
            Currency, 
            name="currency_type", 
            native_enum=False
        ), 
        nullable=False, 
        default=Currency.CAD
    )
    description = Column(String)
    date = Column(
        DateTime, 
        default=datetime.now(UTC)
    )
    created_at = Column(
        DateTime, 
        default=datetime.now(UTC)
    )
    user = relationship(
        argument="User", 
        back_populates="savings"
    )

def init_db():
    Base.metadata.create_all(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()