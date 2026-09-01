import logging
import requests

logger = logging.getLogger(__name__)

# TARUH API KEY & SESSION ID VENUSVERSE KAMU DI SINI:
VENUSVERSE_API_KEY = "c74dbf4cb60e477c98cad3c9fe07cabcaf38677f0a504621ae368a0746736b10"
VENUSVERSE_SESSION_ID = "testing-bot "

def send_wa_notification(message: str, target: str = "kost_channel"):
    """
    Mengirim pesan WA via VenusVerse API
    """
    if VENUSVERSE_API_KEY == "API_KEY_KAMU_DISINI" or VENUSVERSE_SESSION_ID == "SESSION_ID_KAMU_DISINI":
        logger.info(f"[WA_BOT_SIMULATION] (API Key VenusVerse belum diisi). Target: {target} | Msg: {message}")
        print(f"\n{'='*40}\n[WA SIMULASI]\nTarget: {target}\nMessage:\n{message}\n{'='*40}\n")
        return True

    url = f"https://whatsapp.venusverse.me/api/session/{VENUSVERSE_SESSION_ID}/send"
    headers = {
        "x-api-key": VENUSVERSE_API_KEY,
        "Content-Type": "application/json"
    }
    data = {
        "to": target, # Nomor tujuan atau ID Grup WA
        "message": message
    }
    
    try:
        response = requests.post(url, headers=headers, json=data)
        result = response.json()
        logger.info(f"VenusVerse Response: {result}")
        return True
    except Exception as e:
        logger.error(f"Error sending WA notification via VenusVerse: {e}")
        return False
