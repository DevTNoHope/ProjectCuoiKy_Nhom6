# app/core/onesignal.py
import json, requests
from typing import Optional, Dict, List
from app.core.config import settings

class OneSignalClient:
    BASE = "https://api.onesignal.com/notifications"

    def __init__(self, app_id: str, rest_api_key: str):
        self.app_id = app_id
        self.rest_api_key = rest_api_key

    def _headers(self) -> Dict[str, str]:
        return {
            "Authorization": f"Basic {self.rest_api_key}",
            "Content-Type": "application/json; charset=utf-8",
        }

    def send_to_players(
        self,
        player_ids: List[str],
        title_vi: str,
        body_vi: str,
        data: Optional[Dict[str, str]] = None,
    ):
        if not player_ids:
            return None
        payload = {
            "app_id": self.app_id,
            "include_player_ids": player_ids,
            "headings": {"vi": title_vi, "en": title_vi},
            "contents": {"vi": body_vi, "en": body_vi},
            "data": data or {},
            "priority": 10,
        }
        r = requests.post(self.BASE, headers=self._headers(), data=json.dumps(payload), timeout=15)
        r.raise_for_status()
        return r.json()

# Khởi tạo 1 instance dùng chung
onesignal = OneSignalClient(
    app_id=settings.ONESIGNAL_APP_ID,
    rest_api_key=settings.ONESIGNAL_REST_API_KEY,
)
