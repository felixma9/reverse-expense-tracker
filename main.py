from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from database import init_db
from routers import savings, auth, user

app = FastAPI(
    title = "Reverse Expense Tracker",
    version = "1.0.0",
)

app.add_middleware(
    middleware_class=CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup code
    init_db()
    yield
    # Cleanup code

app = FastAPI(lifespan=lifespan)

app.include_router(savings.router, prefix="/savings", tags=["savings"])
app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(user.router, prefix="/users", tags=["users"])

@app.get("/health")
async def health_check():
    return {"status": "ok"}
