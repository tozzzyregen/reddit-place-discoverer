from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from ..supabase_client import supabase

router = APIRouter(prefix="/trips", tags=["trips"])


# Pydantic Models
class CreateTripRequest(BaseModel):
    user_id: str
    title: str


class AddItemRequest(BaseModel):
    trip_id: str
    place_data: dict


class RemoveItemRequest(BaseModel):
    trip_id: str
    place_name: str


def ensure_profile_exists(user_id: str) -> bool:
    """Create profile if it doesn't exist (for foreign key constraint)."""
    try:
        existing = supabase.table("profiles").select("id").eq("id", user_id).execute()
        if existing.data:
            return True
        
        supabase.table("profiles").insert({
            "id": user_id,
            "email": f"{user_id}@placeholder.com",
            "is_pro": False
        }).execute()
        print(f"DEBUG: Created profile for user {user_id}", flush=True)
        return True
    except Exception as e:
        print(f"DEBUG: Profile creation error: {e}", flush=True)
        return False


# ============================================
# IMPORTANT: Specific routes MUST come BEFORE dynamic routes like /{user_id}
# Otherwise FastAPI matches "remove" as a user_id and returns 405
# ============================================

# POST /trips/ - Create a new trip
@router.post("/")
async def create_trip(request: CreateTripRequest):
    """Create a new trip for a user."""
    print(f"DEBUG Trips: Creating trip for user {request.user_id}", flush=True)
    ensure_profile_exists(request.user_id)
    
    try:
        response = supabase.table("trips").insert({
            "user_id": request.user_id,
            "title": request.title,
            "itinerary": []
        }).execute()
        
        return response.data[0] if response.data else {"error": "Failed to create trip"}
    except Exception as e:
        print(f"DEBUG Trips: ERROR = {e}", flush=True)
        raise HTTPException(status_code=500, detail=str(e))


# POST /trips/add - Add place to trip (BEFORE dynamic routes)
@router.post("/add")
async def add_place_to_trip(request: AddItemRequest):
    """Add a place to an existing trip's itinerary."""
    try:
        trip_response = supabase.table("trips").select("*").eq("id", request.trip_id).execute()
        
        if not trip_response.data:
            raise HTTPException(status_code=404, detail="Trip not found")
        
        trip = trip_response.data[0]
        current_itinerary = trip.get("itinerary") or []
        current_itinerary.append(request.place_data)
        
        supabase.table("trips").update({
            "itinerary": current_itinerary
        }).eq("id", request.trip_id).execute()
        
        return {"status": "success", "itinerary_count": len(current_itinerary)}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# POST /trips/remove - Remove place from trip (BEFORE dynamic routes)
@router.post("/remove")
async def remove_place_from_trip(request: RemoveItemRequest):
    """Remove a place from an existing trip's itinerary."""
    print(f"DEBUG: Removing '{request.place_name}' from trip {request.trip_id}", flush=True)
    try:
        trip_response = supabase.table("trips").select("*").eq("id", request.trip_id).execute()
        
        if not trip_response.data:
            raise HTTPException(status_code=404, detail="Trip not found")
        
        trip = trip_response.data[0]
        current_itinerary = trip.get("itinerary") or []
        
        new_itinerary = [
            item for item in current_itinerary 
            if item.get("name") != request.place_name
        ]
        
        supabase.table("trips").update({
            "itinerary": new_itinerary
        }).eq("id", request.trip_id).execute()
        
        print(f"DEBUG: Removed. Itinerary now has {len(new_itinerary)} items", flush=True)
        return {"status": "updated", "itinerary_count": len(new_itinerary)}
    except HTTPException:
        raise
    except Exception as e:
        print(f"DEBUG: Remove error: {e}", flush=True)
        raise HTTPException(status_code=500, detail=str(e))


# GET /trips/test - Test endpoint
@router.get("/test")
async def test_trips():
    return {"status": "trips router works"}


# ============================================
# Dynamic routes MUST come LAST
# ============================================

# GET /trips/{user_id} - Get user's trips
@router.get("/{user_id}")
async def get_user_trips(user_id: str):
    """Get all trips for a user."""
    try:
        response = supabase.table("trips").select("*").eq("user_id", user_id).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# DELETE /trips/{trip_id} - Delete a trip
@router.delete("/{trip_id}")
async def delete_trip(trip_id: str):
    """Delete a trip."""
    try:
        supabase.table("trips").delete().eq("id", trip_id).execute()
        return {"status": "deleted"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
