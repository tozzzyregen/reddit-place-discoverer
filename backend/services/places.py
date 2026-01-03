import os
from pathlib import Path
import requests
from dotenv import load_dotenv

# Load .env from backend folder
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)


def search_google_places(query: str) -> list[dict]:
    """Search for places using Google Places API (New)."""
    load_dotenv(env_path)
    api_key = os.getenv("GOOGLE_PLACES_API_KEY")
    
    print(f"DEBUG: API Key loaded: {bool(api_key)}")
    
    if not api_key:
        print("DEBUG: No API key found!")
        return []
    
    # Using the new Places API (New) endpoint
    url = "https://places.googleapis.com/v1/places:searchText"
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": api_key,
        "X-Goog-FieldMask": "places.id,places.displayName,places.formattedAddress,places.rating,places.photos,places.userRatingCount,places.businessStatus,places.currentOpeningHours"
    }
    payload = {
        "textQuery": query
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload, timeout=10)
        data = response.json()
        print(f"DEBUG: Response status code: {response.status_code}")
        if response.status_code != 200:
            print(f"DEBUG: Error: {data}")
            return []
    except (requests.RequestException, ValueError) as e:
        print(f"DEBUG: Request error: {e}")
        return []
    
    results = []
    for place in data.get("places", []):
        photo_reference = None
        photos = place.get("photos", [])
        if photos:
            photo_reference = photos[0].get("name")  # New API uses 'name' for photo reference
        
        # Get opening hours info
        opening_hours = place.get("currentOpeningHours", {})
        open_now = opening_hours.get("openNow", None)
        
        results.append({
            "name": place.get("displayName", {}).get("text"),
            "place_id": place.get("id"),
            "formatted_address": place.get("formattedAddress"),
            "rating": place.get("rating"),
            "photo_reference": photo_reference,
            "user_ratings_total": place.get("userRatingCount", 0),
            "open_now": open_now,
            "business_status": place.get("businessStatus")
        })
    
    return results

