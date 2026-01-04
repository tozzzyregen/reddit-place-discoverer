import os
import json
from pathlib import Path
from dotenv import load_dotenv
import openai
from exa_py import Exa
from thefuzz import fuzz

# Load environment
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)


class KnowledgeEngine:
    """Double Search Knowledge Engine for travel research."""
    
    def __init__(self):
        self.openai_client = openai.OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
        self.exa = Exa(api_key=os.getenv("EXA_API_KEY"))
    
    def generate_hunter_queries(self, user_query: str) -> list[str]:
        """Generate 3 specific search queries from user's travel query."""
        try:
            response = self.openai_client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {
                        "role": "system",
                        "content": """You are a research expert. Convert the user's travel query into 3 specific, distinct search queries for a search engine:
1. A Reddit-focused query for opinions (e.g., 'site:reddit.com best jazz bars Tokyo').
2. A 'Hidden Gem' or Blog query (e.g., 'underrated jazz bars Tokyo blog').
3. A specific 'Best of' list query (e.g., 'top rated jazz bars Tokyo 2024').

Return ONLY a JSON array of 3 strings, no other text."""
                    },
                    {
                        "role": "user",
                        "content": user_query
                    }
                ],
                temperature=0.7,
            )
            
            content = response.choices[0].message.content.strip()
            # Parse JSON array
            if content.startswith("["):
                queries = json.loads(content)
            else:
                # Try to extract JSON from response
                start = content.find("[")
                end = content.rfind("]") + 1
                queries = json.loads(content[start:end])
            
            print(f"DEBUG: Generated hunter queries: {queries}")
            return queries[:3]  # Ensure max 3 queries
            
        except Exception as e:
            print(f"Error generating hunter queries: {e}")
            # Fallback queries
            return [
                f"site:reddit.com {user_query} reviews",
                f"{user_query} hidden gems blog",
                f"best {user_query} 2024"
            ]
    
    def broad_search(self, queries: list[str]) -> list[dict]:
        """Execute broad search across multiple queries using Exa."""
        all_results = []
        
        for query in queries:
            try:
                print(f"DEBUG: Searching Exa for: {query}")
                response = self.exa.search_and_contents(
                    query,
                    num_results=3,
                    use_autoprompt=True
                )
                
                for result in response.results:
                    all_results.append({
                        "url": result.url,
                        "title": result.title or "",
                        "text": result.text[:1000] if result.text else "",
                        "source_query": query
                    })
                    
            except Exception as e:
                print(f"Error searching Exa for '{query}': {e}")
                continue
        
        print(f"DEBUG: Broad search found {len(all_results)} total results")
        return all_results
    
    def deduplicate_results(self, raw_results: list[dict]) -> list[dict]:
        """Remove duplicate results based on title similarity."""
        if not raw_results:
            return []
        
        unique_results = []
        
        for result in raw_results:
            is_duplicate = False
            title = result.get("title", "")
            
            for i, unique in enumerate(unique_results):
                unique_title = unique.get("title", "")
                
                # Check similarity
                similarity = fuzz.ratio(title.lower(), unique_title.lower())
                
                if similarity > 85:
                    is_duplicate = True
                    # Keep the one with more text
                    if len(result.get("text", "")) > len(unique.get("text", "")):
                        unique_results[i] = result
                    break
            
            if not is_duplicate:
                unique_results.append(result)
        
        print(f"DEBUG: Deduplicated from {len(raw_results)} to {len(unique_results)} results")
        return unique_results
