from fastapi import APIRouter, Query

from ..services.ai_agent import get_vibe_check
from ..services.social_service import get_social_links
from ..services.cache_service import get_cached_location, save_location_to_cache

router = APIRouter(prefix="/analyze", tags=["analyze"])


@router.get("/")
async def analyze_location(
    name: str = Query(..., description="Location name to analyze"),
    place_id: str = Query(None, description="Google Place ID (optional)")
):
    """Get a Vibe Check analysis for a location with social links."""
    
    # Check cache first
    cached_data = get_cached_location(name)
    
    if cached_data:
        print("Serving from Cache (Free!)")
        result = cached_data.get("ai_summary", {})
        result["social_links"] = cached_data.get("social_links", [])
        return result
    
    # Cache miss - call expensive APIs
    print("Cache Miss - Calling APIs (Expensive...)")
    vibe = get_vibe_check(name)
    links = get_social_links(name)
    
    # Save to cache for next time
    save_location_to_cache(name, place_id, vibe, links)
    
    vibe["social_links"] = links
    return vibe

