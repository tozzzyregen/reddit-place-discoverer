from fastapi import APIRouter, HTTPException

from ..supabase_client import supabase

router = APIRouter(prefix="/profile", tags=["profile"])


@router.get("/{user_id}")
async def get_profile(user_id: str):
    """Get user profile by ID (bypasses RLS using service role)."""
    print(f"DEBUG Profile API: Getting profile for {user_id}", flush=True)
    
    try:
        response = supabase.table("profiles").select("*").eq("id", user_id).execute()
        
        if response.data and len(response.data) > 0:
            profile = response.data[0]
            print(f"DEBUG Profile API: Found profile = {profile}", flush=True)
            return {
                "id": profile.get("id"),
                "email": profile.get("email"),
                "is_pro": profile.get("is_pro", False),
                "stripe_id": profile.get("stripe_id"),
            }
        else:
            print(f"DEBUG Profile API: No profile found for {user_id}", flush=True)
            return {
                "id": user_id,
                "email": None,
                "is_pro": False,
                "stripe_id": None,
            }
    except Exception as e:
        print(f"DEBUG Profile API: Error = {e}", flush=True)
        raise HTTPException(status_code=500, detail=str(e))


