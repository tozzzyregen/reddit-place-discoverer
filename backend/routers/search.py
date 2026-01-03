import os
from fastapi import APIRouter, Query, Response, HTTPException
from fastapi.responses import Response
import requests

from ..services.places import search_google_places

router = APIRouter(prefix="/search", tags=["search"])


@router.get("/query")
async def search_places(q: str = Query(..., description="Search query for places")):
    """Search for places using Google Places API."""
    print("Endpoint hit!")
    results = search_google_places(q)
    return results


@router.get("/photo")
async def get_photo(
    reference: str = Query(..., description="Photo reference from Google Places"),
    maxwidth: int = Query(400, description="Maximum width of the photo"),
):
    """Proxy endpoint to serve Google Place Photos securely."""
    api_key = os.getenv("GOOGLE_PLACES_API_KEY")
    
    if not api_key:
        raise HTTPException(status_code=500, detail="API key not configured")
    
    # New Places API (v1) uses different URL format
    # Reference looks like: "places/{placeId}/photos/{photoId}"
    url = f"https://places.googleapis.com/v1/{reference}/media?maxWidthPx={maxwidth}&key={api_key}"
    
    try:
        response = requests.get(url, stream=True, timeout=10)
        print(f"DEBUG Photo proxy: status={response.status_code}, url={url[:80]}...")
        
        if response.status_code != 200:
            print(f"DEBUG Photo error: {response.text[:200]}")
            raise HTTPException(status_code=404, detail="Photo not found")
        
        content_type = response.headers.get("Content-Type", "image/jpeg")
        
        return Response(
            content=response.content,
            media_type=content_type,
        )
    except requests.RequestException as e:
        print(f"Error fetching photo: {e}")
        raise HTTPException(status_code=404, detail="Failed to fetch photo")
