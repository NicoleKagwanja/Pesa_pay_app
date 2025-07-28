from fastapi import FastAPI
from routes.auth import router as auth_router
from routes.off_week import router as off_week_router

app = FastAPI()

app.include_router(auth_router, prefix="/api")
app.include_router(off_week_router, prefix="/api")

@app.get("/")
def read_root():
    return {"message": "Pesa Pay Backend"}
