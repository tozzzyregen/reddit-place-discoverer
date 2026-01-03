import os
from pathlib import Path
from dotenv import load_dotenv
from supabase import create_client, Client

# Load .env from backend folder
env_path = Path(__file__).parent / ".env"
load_dotenv(env_path)

SUPABASE_URL = os.getenv("SUPABASE_URL")
# Use SERVICE_ROLE key for backend (bypasses RLS)
# Find it in: Supabase Dashboard → Settings → API → service_role (secret)
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

# Fallback to old key name for compatibility
if not SUPABASE_SERVICE_KEY:
    SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_KEY")
    print("WARNING: Using SUPABASE_KEY. For RLS bypass, use SUPABASE_SERVICE_KEY instead.")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY) if SUPABASE_URL and SUPABASE_SERVICE_KEY else None

