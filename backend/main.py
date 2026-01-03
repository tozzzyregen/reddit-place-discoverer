from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .routers import search, analyze, trips, payments, profile

app = FastAPI(title="The Vibe Check API")

# Allow all origins for mobile app access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(search.router)
app.include_router(analyze.router)
app.include_router(trips.router)
app.include_router(payments.router)
app.include_router(profile.router)


@app.on_event("startup")
async def startup_event():
    print("Server running...")
    print("Search module created. Endpoint available at /search/query")
    print("AI Service Ready")
    print("Social Service Integrated")
    print("Caching System Active")
    print("Trips Router Active")
    print("Trip Management Logic Added")
    print("Payment Router Ready")
    print("Profile API Ready")


@app.get("/")
async def root():
    return {"status": "API is running"}

