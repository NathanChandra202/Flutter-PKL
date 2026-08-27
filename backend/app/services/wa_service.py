import requests

logger = logging.getLogger(__name__)

# TARUH TOKEN FONNTE KAMU DI SINI:
FONNTE_TOKEN = "m4iuPPzJw7EfYA8uySSq"

def send_wa_notification(message: str, target: str = "kost_channel"):
    """
    Mengirim pesan WA via Fonnte API
    """
    if FONNTE_TOKEN == "TOKEN_FONNTE_KAMU_DISINI":
        logger.info(f"[WA_BOT_SIMULATION] (Token Fonnte belum diisi). Target: {target} | Msg: {message}")
        print(f"\n{'='*40}\n[WA SIMULASI]\nTarget: {target}\nMessage:\n{message}\n{'='*40}\n")
        return True

    url = "https://api.fonnte.com/send"
    headers = {
        "Authorization": FONNTE_TOKEN
    }
    data = {
        "target": target, # Nomor tujuan atau ID Grup WA
        "message": message,
        "countryCode": "62" # Format Indonesia
    }
    
    try:
        response = requests.post(url, headers=headers, data=data)
        result = response.json()
        logger.info(f"Fonnte Response: {result}")
        return True
    except Exception as e:
        logger.error(f"Error sending WA notification via Fonnte: {e}")
        return False
