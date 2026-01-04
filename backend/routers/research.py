from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional

from ..services.knowledge_engine import KnowledgeEngine
from ..services.places import search_google_places
from ..supabase_client import supabase

router = APIRouter(prefix="/research", tags=["research"])


class ResearchRequest(BaseModel):
    query: str
    user_id: Optional[str] = None


@router.post("")
async def research(request: ResearchRequest):
    """Execute double search research on a query with Smart Cache."""
    try:
        # Step 1: Check the Cache
        print(f"DEBUG: Checking cache for '{request.query}'")
        cached_results = []
        
        try:
            # Simple text search in places table
            cache_response = supabase.table("places").select("*").ilike(
                "name", f"%{request.query}%"
            ).execute()
            cached_results = cache_response.data or []
        except Exception as e:
            print(f"Warning: Cache check failed: {e}")
        
        # Step 2: Evaluate Freshness
        if len(cached_results) > 3:
            # Check if results are fresh (less than 7 days old)
            fresh_results = []
            cutoff_date = datetime.now(timezone.utc) - timedelta(days=7)
            
            for place in cached_results:
                last_updated = place.get("last_updated")
                if last_updated:
                    try:
                        # Parse the timestamp
                        if isinstance(last_updated, str):
                            updated_dt = datetime.fromisoformat(last_updated.replace("Z", "+00:00"))
                        else:
                            updated_dt = last_updated
                        
                        if updated_dt > cutoff_date:
                            fresh_results.append(place)
                    except:
                        fresh_results.append(place)  # Include if can't parse date
                else:
                    fresh_results.append(place)  # Include if no date
            
            if len(fresh_results) > 3:
                print(f"DEBUG: Returning {len(fresh_results)} cached results (MEMORY HIT)")
                
                # Log the search
                try:
                    log_data = {"user_query": request.query, "refined_intent": ["cache_hit"]}
                    if request.user_id:
                        log_data["user_id"] = request.user_id
                    supabase.table("search_logs").insert(log_data).execute()
                except:
                    pass
                
                # Return cached results with database IDs
                results = [{
                    "id": p.get("id"),
                    "title": p.get("name", ""),
                    "text": p.get("description", ""),
                    "url": p.get("source_links", [""])[0] if p.get("source_links") else "",
                    "source_type": "memory"
                } for p in fresh_results]
                
                return {
                    "query": request.query,
                    "hunter_queries": [],
                    "results": results,
                    "total_results": len(results),
                    "source_type": "memory"
                }
        
        # Step 3: Fallback to Live Search (The Hunter)
        print(f"DEBUG: No cache hit, running live search...")
        engine = KnowledgeEngine()
        
        # Generate hunter queries
        hunter_queries = engine.generate_hunter_queries(request.query)
        
        # Broad search
        raw_results = engine.broad_search(hunter_queries)
        
        # Deduplicate results
        final_results = engine.deduplicate_results(raw_results)
        
        # Log to database
        try:
            log_data = {"user_query": request.query, "refined_intent": hunter_queries}
            if request.user_id:
                log_data["user_id"] = request.user_id
            supabase.table("search_logs").insert(log_data).execute()
        except Exception as e:
            print(f"Warning: Failed to log search: {e}")
        
        # Save results to places table and collect names
        saved_names = []
        for result in final_results:
            try:
                name = result.get("title", "")[:255]
                
                # Skip if no title
                if not name:
                    continue
                
                place_data = {
                    "name": name,
                    "description": result.get("text", "")[:500],
                    "source_links": [result.get("url", "")],
                    "last_updated": "now()"
                }
                
                supabase.table("places").upsert(
                    place_data,
                    on_conflict="name"
                ).execute()
                saved_names.append(name)
                
            except Exception as e:
                print(f"Warning: Failed to save place '{result.get('title', '')}': {e}")
        
        print(f"Results saved to Persistent Memory: {len(saved_names)} places")
        
        # Retrieve saved rows with database IDs
        db_results = []
        if saved_names:
            try:
                db_response = supabase.table("places").select("*").in_("name", saved_names).execute()
                db_results = [{
                    "id": p.get("id"),
                    "title": p.get("name", ""),
                    "text": p.get("description", ""),
                    "url": p.get("source_links", [""])[0] if p.get("source_links") else "",
                    "source_type": "live"
                } for p in (db_response.data or [])]
            except Exception as e:
                print(f"Warning: Failed to retrieve saved places: {e}")
                # Fallback to original results without IDs
                db_results = [{
                    "title": r.get("title", ""),
                    "text": r.get("text", ""),
                    "url": r.get("url", ""),
                    "source_type": "live"
                } for r in final_results]
        
        print("Search now returns Database IDs")
        
        return {
            "query": request.query,
            "hunter_queries": hunter_queries,
            "results": db_results,
            "total_results": len(db_results),
            "source_type": "live"
        }
        
    except Exception as e:
        print(f"Research error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/places/{place_id}")
async def get_place_detail(place_id: str):
    """Get place details with on-demand enrichment (Layer 2 Search)."""
    try:
        # Step 1: Fetch from DB
        response = supabase.table("places").select("*").eq("id", place_id).execute()
        
        if not response.data:
            raise HTTPException(status_code=404, detail="Place not found")
        
        place = response.data[0]
        print(f"DEBUG: Fetched place '{place.get('name')}'")
        
        # Step 2: Check for Google ID / Photo - Trigger Enrichment if missing
        if not place.get("google_place_id") or not place.get("photo_reference"):
            print(f"DEBUG: Enriching place '{place.get('name')}'...")
            
            try:
                # Search Google Places for this place
                google_results = search_google_places(place.get("name", ""))
                
                if google_results:
                    first_result = google_results[0]
                    
                    # Prepare update data
                    update_data = {
                        "google_place_id": first_result.get("place_id"),
                        "formatted_address": first_result.get("formatted_address"),
                        "photo_reference": first_result.get("photo_reference"),
                        "rating": first_result.get("rating"),
                        "user_ratings_total": first_result.get("user_ratings_total", 0),
                        "last_updated": "now()"
                    }
                    
                    # Update DB
                    supabase.table("places").update(update_data).eq("id", place_id).execute()
                    
                    # Merge into local place object
                    place.update(update_data)
                    print(f"DEBUG: Enrichment complete for '{place.get('name')}'")
                else:
                    print(f"DEBUG: No Google results found for '{place.get('name')}'")
                    
            except Exception as e:
                print(f"Warning: Enrichment failed: {e}")
        
        # Step 3: Return enriched data
        return {
            "id": place.get("id"),
            "name": place.get("name"),
            "description": place.get("description"),
            "formatted_address": place.get("formatted_address"),
            "google_place_id": place.get("google_place_id"),
            "photo_reference": place.get("photo_reference"),
            "rating": place.get("rating"),
            "user_ratings_total": place.get("user_ratings_total"),
            "source_links": place.get("source_links"),
            "last_updated": place.get("last_updated")
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Place detail error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


print("Smart Cache Layer Active")
print("Deep Dive Endpoint Ready")
