from datetime import datetime, timedelta, timezone
from ..supabase_client import supabase


def get_cached_location(name: str) -> dict | None:
    """Get cached location data if it exists and is fresh (< 7 days old)."""
    
    try:
        response = supabase.table("locations").select("*").ilike("name", name).execute()
        
        if not response.data:
            return None
        
        location = response.data[0]
        last_updated = datetime.fromisoformat(location["last_updated"].replace("Z", "+00:00"))
        
        # Check if cache is still fresh (less than 7 days old)
        if datetime.now(timezone.utc) - last_updated > timedelta(days=7):
            return None
        
        return location
        
    except Exception as e:
        print(f"Cache Read Error: {e}")
        return None


def save_location_to_cache(name: str, place_id: str, ai_data: dict, social_links: list) -> bool:
    """Save or update location data in the cache."""
    
    try:
        data = {
            "name": name,
            "google_place_id": place_id or f"manual_{name.lower().replace(' ', '_')}",
            "reddit_score": ai_data.get("reddit_score"),
            "ai_summary": ai_data,
            "social_links": social_links,
            "last_updated": datetime.now(timezone.utc).isoformat()
        }
        
        # Upsert based on name (using google_place_id as unique constraint)
        response = supabase.table("locations").upsert(
            data,
            on_conflict="google_place_id"
        ).execute()
        
        return True
        
    except Exception as e:
        print(f"Cache Write Error: {e}")
        return False

