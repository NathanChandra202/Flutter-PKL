import logging
import requests
import urllib.parse

logger = logging.getLogger(__name__)

import os
from dotenv import load_dotenv

load_dotenv()

VENUSVERSE_API_KEY = os.getenv("VENUSVERSE_API_KEY", "")
VENUSVERSE_SESSION_ID = os.getenv("VENUSVERSE_SESSION_ID", "")
def send_wa_notification(message: str, target: str = "kost_channel"):
    """
    Mengirim pesan WA via VenusVerse API
    """
    if not VENUSVERSE_API_KEY or not VENUSVERSE_SESSION_ID or VENUSVERSE_API_KEY == "API_KEY_KAMU_DISINI":
        logger.info(f"[WA_BOT_SIMULATION] (API Key VenusVerse belum diisi/tidak ada di .env). Target: {target} | Msg: {message}")
        print(f"\n{'='*40}\n[WA SIMULASI]\nTarget: {target}\nMessage:\n{message}\n{'='*40}\n")
        return True

    session_id_safe = urllib.parse.quote(VENUSVERSE_SESSION_ID.strip())
    url = f"https://whatsapp.venusverse.me/api/session/{session_id_safe}/send"
    headers = {
        "x-api-key": VENUSVERSE_API_KEY.strip(),
        "Content-Type": "application/json"
    }
    data = {
        "to": target, # Nomor tujuan atau ID Grup WA
        "message": message
    }
    
    try:
        response = requests.post(url, headers=headers, json=data, timeout=10)
        # Parse JSON manually to avoid exceptions on non-JSON error pages
        if response.status_code != 200:
            logger.error(f"[WA_BOT] Failed to send message. HTTP {response.status_code}: {response.text}")
            print(f"WA API ERROR: {response.text}")
            return False
            
        result = response.json()
        logger.info(f"VenusVerse Response: {result}")
        return True
    except Exception as e:
        logger.error(f"Error sending WA notification via VenusVerse: {e}")
        print(f"WA EXCEPTION: {e}")
        return False
