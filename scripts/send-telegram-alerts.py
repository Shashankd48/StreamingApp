#!/usr/bin/env python3
"""
StreamFlix ChatOps Alert Dispatcher for Telegram
Dispatches real-time CI/CD deployment statuses and AWS CloudWatch alarms
to the dedicated Telegram Operations Bot (@shashank_streamflix_bot).
"""

import os
import sys
import json
import time
import urllib.request
import urllib.parse

# Credentials retrieved securely from environment or Jenkins credentials
BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "8926420247:AAGWCF3tXuUap1hBtWfe8fvixwm0NADrK5g")
CHAT_ID = os.getenv("TELEGRAM_CHAT_ID", "8868274174")

def send_telegram_alert(text: str, parse_mode: str = "Markdown") -> bool:
    """Dispatches a formatted Markdown alert to the target Telegram Chat."""
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage"
    payload = {
        "chat_id": CHAT_ID,
        "text": text,
        "parse_mode": parse_mode,
        "disable_web_page_preview": True
    }
    
    try:
        req = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"}
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            if data.get("ok"):
                msg_id = data["result"]["message_id"]
                print(f"[SUCCESS] Telegram alert delivered (Message ID: {msg_id})")
                return True
            else:
                print(f"[ERROR] Telegram API rejected message: {data}")
                return False
    except Exception as err:
        print(f"[ERROR] Failed to send Telegram alert: {err}", file=sys.stderr)
        return False

if __name__ == "__main__":
    if len(sys.argv) > 1:
        custom_msg = " ".join(sys.argv[1:])
        send_telegram_alert(custom_msg)
    else:
        print("Usage: python send-telegram-alerts.py '<message>'")
