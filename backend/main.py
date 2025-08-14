from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from routers import auth, off_week, admin, salary, attendance

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("\n" + "="*50)
    print("PESA PAY BACKEND STARTING UP")
    print("="*50)
    print("Registered Routes:")
    for route in app.routes:
        if hasattr(route, "methods"):
            methods = ", ".join(sorted(route.methods - {"HEAD", "OPTIONS"}))
            path = route.path
            print(f"  {methods: <12} {path}")
        elif hasattr(route, "path"):
            print(f"  [MOUNT]     {route.path}")
        else:
            print(f"  [ROUTE]     {route}")
    print("="*50)

    yield

    print("PESA PAY BACKEND SHUTTING DOWN")
    print("="*50)

app = FastAPI(
    title="Pesa Pay API",
    description="Employee payroll and attendance system",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/")
def read_root():
    return {
        "message": "NICOLE KAGWANJA",
    }

@app.get("/favicon.ico", include_in_schema=False)
async def favicon():
    return FileResponse("static/favicon.ico")

app.include_router(auth.router, prefix="/api/v1")
app.include_router(off_week.router, prefix="/api/v1")
app.include_router(admin.router, prefix="/api/v1")
app.include_router(salary.router, prefix="/api/v1")
app.include_router(attendance.router, prefix="/api/v1")