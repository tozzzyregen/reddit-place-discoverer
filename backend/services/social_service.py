import os
from pathlib import Path
from dotenv import load_dotenv
from exa_py import Exa

# Load .env from backend folder
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)


def get_social_links(location_name: str) -> list[str]:
    """Fetch TikTok and Instagram links for a location using Exa AI."""
    
    api_key = os.getenv("EXA_API_KEY")
    print(f"DEBUG Social: API Key loaded: {bool(api_key)}")
    
    if not api_key:
        print("DEBUG Social: No EXA_API_KEY found!")
        return []
    
    try:
        exa = Exa(api_key=api_key)
        
        results = exa.search(
            query=f"aesthetic travel vlog {location_name} site:tiktok.com",
            num_results=6,
            start_published_date="2024-01-01"
        )
        
        print(f"DEBUG Social: Found {len(results.results)} results")
        urls = [result.url for result in results.results]
        return urls
        
    except Exception as e:
        print(f"Social Service Error: {e}")
        return []

