import os
from pathlib import Path
from dotenv import load_dotenv
from fastapi import APIRouter, HTTPException, Request, Header
from pydantic import BaseModel
import stripe

from ..supabase_client import supabase

# Load environment variables
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(env_path)

# Initialize Stripe
stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET")

router = APIRouter(prefix="/payments", tags=["payments"])

print("Webhook Listener Ready", flush=True)


class CheckoutRequest(BaseModel):
    user_id: str


@router.post("/create-checkout-session")
async def create_checkout_session(request: CheckoutRequest):
    """Create a Stripe Checkout Session for upgrading to Nomad (Pro)."""
    print(f"DEBUG Payments: Creating checkout for user {request.user_id}", flush=True)
    
    if not stripe.api_key:
        print("ERROR: STRIPE_SECRET_KEY not configured!", flush=True)
        raise HTTPException(status_code=500, detail="Payment system not configured")
    
    try:
        session = stripe.checkout.Session.create(
            payment_method_types=["card"],
            line_items=[{
                "price": "price_1SlGr3E7Rsu6Zaew312a9rnS",
                "quantity": 1
            }],
            mode="subscription",
            success_url="http://localhost:8001/payments/success?session_id={CHECKOUT_SESSION_ID}",
            cancel_url="http://localhost:8001/payments/cancel",
            client_reference_id=request.user_id,  # Links payment to user
        )
        
        print(f"DEBUG Payments: Checkout session created: {session.id}", flush=True)
        return {"checkoutUrl": session.url}
    
    except stripe.error.StripeError as e:
        print(f"DEBUG Payments: Stripe error: {e}", flush=True)
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        print(f"DEBUG Payments: Error: {e}", flush=True)
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/success")
async def payment_success(session_id: str):
    """Handle successful payment redirect."""
    print(f"DEBUG Payments: Success callback for session {session_id}", flush=True)
    return {
        "status": "success",
        "message": "Payment successful! You are now a Nomad.",
        "session_id": session_id
    }


@router.get("/cancel")
async def payment_cancel():
    """Handle cancelled payment redirect."""
    print("DEBUG Payments: Payment cancelled", flush=True)
    return {
        "status": "cancelled",
        "message": "Payment was cancelled."
    }


@router.post("/webhook")
async def stripe_webhook(request: Request, stripe_signature: str = Header(None)):
    """Handle Stripe webhook events."""
    payload = await request.body()
    
    if not STRIPE_WEBHOOK_SECRET:
        print("WARNING: STRIPE_WEBHOOK_SECRET not configured!", flush=True)
        # For testing without signature verification
        try:
            event = stripe.Event.construct_from(
                stripe.util.convert_to_stripe_object(payload),
                stripe.api_key
            )
        except Exception as e:
            print(f"Webhook error (no secret): {e}", flush=True)
            raise HTTPException(status_code=400, detail=str(e))
    else:
        # Verify webhook signature
        try:
            event = stripe.Webhook.construct_event(
                payload, stripe_signature, STRIPE_WEBHOOK_SECRET
            )
        except stripe.error.SignatureVerificationError as e:
            print(f"Webhook signature verification failed: {e}", flush=True)
            raise HTTPException(status_code=400, detail="Invalid signature")
        except Exception as e:
            print(f"Webhook error: {e}", flush=True)
            raise HTTPException(status_code=400, detail=str(e))
    
    print(f"Webhook received: {event['type']}", flush=True)
    
    # Handle the checkout.session.completed event
    if event['type'] == 'checkout.session.completed':
        session = event['data']['object']
        user_id = session.get('client_reference_id')
        customer_id = session.get('customer')
        
        print(f"DEBUG: checkout.session.completed - user_id={user_id}, customer_id={customer_id}", flush=True)
        
        if user_id:
            try:
                # Get customer email from Stripe
                customer_email = session.get('customer_email') or session.get('customer_details', {}).get('email')
                print(f"DEBUG: Customer email from Stripe = {customer_email}", flush=True)
                
                # First, ensure profile exists (upsert)
                existing = supabase.table("profiles").select("id, email").eq("id", user_id).execute()
                
                if not existing.data:
                    # Create profile if it doesn't exist
                    print(f"DEBUG: Creating profile for user {user_id}", flush=True)
                    supabase.table("profiles").insert({
                        "id": user_id,
                        "email": customer_email or f"{user_id}@user.com",
                        "is_pro": True,
                        "stripe_id": customer_id
                    }).execute()
                else:
                    # Update existing profile to Pro
                    print(f"DEBUG: Updating existing profile for user {user_id}", flush=True)
                    update_data = {
                        "is_pro": True,
                        "stripe_id": customer_id
                    }
                    # Also update email if we have a real one and current is placeholder
                    current_email = existing.data[0].get('email', '')
                    if customer_email and ('placeholder' in current_email or '@user.com' in current_email):
                        update_data['email'] = customer_email
                    
                    result = supabase.table("profiles").update(update_data).eq("id", user_id).execute()
                    print(f"DEBUG: Update result = {result}", flush=True)
                
                print(f"UPGRADED USER {user_id} TO PRO!", flush=True)
            except Exception as e:
                print(f"Error upgrading user: {e}", flush=True)
        else:
            print("WARNING: No client_reference_id in session", flush=True)
    
    # Handle subscription cancellation
    elif event['type'] == 'customer.subscription.deleted':
        subscription = event['data']['object']
        customer_id = subscription.get('customer')
        
        if customer_id:
            try:
                # Downgrade user from Pro
                supabase.table("profiles").update({
                    "is_pro": False
                }).eq("stripe_id", customer_id).execute()
                
                print(f"DOWNGRADED customer {customer_id} from Pro", flush=True)
            except Exception as e:
                print(f"Error downgrading user: {e}", flush=True)
    
    return {"status": "success"}

