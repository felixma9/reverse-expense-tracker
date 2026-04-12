from datetime import datetime
from enum import StrEnum

from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, String, Enum as SQLEnum, create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship, sessionmaker

DATABASE_URL = "sqlite:///./app.db"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)
Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False)
    created_at = Column(DateTime, default=datetime.now())
    savings = relationship("Saving", back_populates="user")
    
class Currency(StrEnum):
    CAD = "CAD"
    USD = "USD"
    EUR = "EUR"
    JPY = "JPY"

class Saving(Base):
    __tablename__ = "savings"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    amount = Column(Float, nullable=False)
    currency = Column(SQLEnum(Currency, name="currency_type", native_enum=False), nullable=False, default=Currency.CAD)
    description = Column(String)
    date = Column(DateTime, default=datetime.now())
    created_at = Column(DateTime, default=datetime.now())
    user = relationship("User", back_populates="savings")
    
def seed_user(db):
    existing = db.query(User).first()
    if not existing:
        db.add(User(name="John Doe", email="john.doe@example.com"))
        db.commit()

def init_db():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        seed_user(db)
    finally:
        db.close()