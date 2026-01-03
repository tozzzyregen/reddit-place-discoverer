import os
import json
import re
from pathlib import Path
import openai
from dotenv import load_dotenv

# Load .env from backend folder
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)


def extract_json(text: str) -> dict:
    """Extract JSON from text that may contain markdown or extra content."""
    # Try direct parsing first
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    
    # Try to find JSON in code blocks
    code_block_match = re.search(r'```(?:json)?\s*([\s\S]*?)\s*```', text)
    if code_block_match:
        try:
            return json.loads(code_block_match.group(1))
        except json.JSONDecodeError:
            pass
    
    # Try to find JSON object in text
    json_match = re.search(r'\{[\s\S]*\}', text)
    if json_match:
        try:
            return json.loads(json_match.group())
        except json.JSONDecodeError:
            pass
    
    raise json.JSONDecodeError("No valid JSON found", text, 0)


def get_vibe_check(location_name: str) -> dict:
    """Generate a Vibe Check for a location using Perplexity API."""
    
    client = openai.OpenAI(
        api_key=os.getenv("PERPLEXITY_API_KEY"),
        base_url="https://api.perplexity.ai"
    )
    
    system_message = "You are a travel expert who analyzes Reddit discussions. Return ONLY a valid JSON object with no markdown, no code blocks, no explanation."
    
    user_message = f"""Search Reddit for recent travel discussions about {location_name}. Analyze the sentiment.
Return ONLY this JSON structure (no other text):
{{"verdict": "3 word verdict", "reddit_score": 8.5, "pros": ["pro1", "pro2", "pro3"], "cons": ["con1", "con2", "con3"], "scams": ["scam1"], "best_for": ["Solo", "Couples"]}}"""

    try:
        response = client.chat.completions.create(
            model="sonar",
            messages=[
                {"role": "system", "content": system_message},
                {"role": "user", "content": user_message}
            ]
        )
        
        content = response.choices[0].message.content
        print(f"DEBUG: Raw API response: {content[:500]}")
        
        result = extract_json(content)
        return result
        
    except json.JSONDecodeError as e:
        print(f"JSON Parse Error: {e}")
        return {
            "verdict": "Analysis Failed",
            "reddit_score": 0.0,
            "pros": ["Unable to parse response"],
            "cons": ["API returned invalid JSON"],
            "scams": [],
            "best_for": []
        }
    except Exception as e:
        print(f"AI Agent Error: {e}")
        return {
            "verdict": "Service Unavailable",
            "reddit_score": 0.0,
            "pros": [],
            "cons": [str(e)],
            "scams": [],
            "best_for": []
        }

