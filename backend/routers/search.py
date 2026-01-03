from fastapi import APIRouter, Query

from ..services.places import search_google_places

router = APIRouter(prefix="/search", tags=["search"])


@router.get("/query")
async def search_places(q: str = Query(..., description="Search query for places")):
    """Search for places using Google Places API."""
    print("Endpoint hit!")
    results = search_google_places(q)
    return results

