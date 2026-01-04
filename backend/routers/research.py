from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional

from ..services.knowledge_engine import KnowledgeEngine
from ..supabase_client import supabase

router = APIRouter(prefix="/research", tags=["research"])


class ResearchRequest(BaseModel):
    query: str
    user_id: Optional[str] = None


@router.post("")
async def research(request: ResearchRequest):
    """Execute double search research on a query."""
    try:
        engine = KnowledgeEngine()
        
        # Step 1: Generate hunter queries
        hunter_queries = engine.generate_hunter_queries(request.query)
        
        # Step 2: Broad search
        raw_results = engine.broad_search(hunter_queries)
        
        # Step 3: Deduplicate results
        final_results = engine.deduplicate_results(raw_results)
        
        # Step 4: Log to database
        try:
            supabase.table("search_logs").insert({
                "user_query": request.query,
                "refined_intent": hunter_queries,
                "user_id": request.user_id
            }).execute()
        except Exception as e:
            print(f"Warning: Failed to log search: {e}")
        
        # Step 5: Save results to places table
        saved_count = 0
        for result in final_results:
            try:
                place_data = {
                    "name": result.get("title", "")[:255],
                    "description": result.get("text", "")[:500],
                    "source_links": [result.get("url", "")],
                    "last_updated": "now()"
                }
                
                # Skip if no title
                if not place_data["name"]:
                    continue
                
                supabase.table("places").upsert(
                    place_data,
                    on_conflict="name"
                ).execute()
                saved_count += 1
                
            except Exception as e:
                print(f"Warning: Failed to save place '{result.get('title', '')}': {e}")
        
        print(f"Results saved to Persistent Memory: {saved_count} places")
        
        return {
            "query": request.query,
            "hunter_queries": hunter_queries,
            "results": final_results,
            "total_results": len(final_results)
        }
        
    except Exception as e:
        print(f"Research error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
