# app/services/gemini_image_url_service.py
import base64
from io import BytesIO
from uuid import uuid4
from pathlib import Path
from typing import List
from PIL import Image
from google import genai
from app.core.config import settings

ALLOWED_IN_MIME = {"image/jpeg", "image/png", "image/webp"}

class GeminiImageUrlService:
    def __init__(self):
        if not settings.GEMINI_API_KEY:
            raise RuntimeError("GEMINI_API_KEY not set")
        self.client = genai.Client(api_key=settings.GEMINI_API_KEY)
        self.model = settings.AI_MODEL_ID

    def _save_image_bytes(self, raw: bytes, to_dir: Path, to_format="PNG") -> str:
        """
        Lưu raw bytes (từ Gemini) vào to_dir (phải nằm trong STATIC),
        trả về URL dưới dạng /static/...
        """
        from pathlib import Path
        image = Image.open(BytesIO(raw)).convert("RGB")
    
        # chuẩn hoá absolute
        static_root = Path("static").resolve()
        to_dir_abs = (to_dir if isinstance(to_dir, Path) else Path(to_dir)).resolve()
    
        # nếu to_dir nằm ngoài static → ép về static/ai_results
        if not str(to_dir_abs).startswith(str(static_root)):
            to_dir_abs = (static_root / "ai_results").resolve()
    
        to_dir_abs.mkdir(parents=True, exist_ok=True)
        filename = f"{uuid4().hex}.png" if to_format.upper() == "PNG" else f"{uuid4().hex}.jpg"
        out_path = (to_dir_abs / filename).resolve()
    
        image.save(out_path, format=to_format.upper())
    
        # tính relative path an toàn
        rel = out_path.relative_to(static_root)
        return f"/static/{rel.as_posix()}"


    def edit_image_and_get_urls(self, image_bytes: bytes, mime_type: str, prompt: str) -> List[str]:
        if mime_type not in ALLOWED_IN_MIME:
            raise ValueError("Unsupported image mime type")

        # SDK google-genai yêu cầu ảnh inline dạng base64 đặt trong inline_data
        b64 = base64.b64encode(image_bytes).decode("ascii")

        resp = self.client.models.generate_content(
            model=self.model,
            contents=[{
                "role": "user",
                "parts": [
                    {"text": prompt},
                    {"inline_data": {"mime_type": mime_type, "data": b64}},
                ],
            }],
            # chỉ trả ảnh (nếu model hỗ trợ)
            config={"response_modalities": ["TEXT","IMAGE"]},
        )

        if not resp or not resp.candidates:
            raise RuntimeError("No candidates from Gemini")

        urls: List[str] = []
        cand = resp.candidates[0]
        for part in cand.content.parts:
            if getattr(part, "inline_data", None):
                raw = part.inline_data.data  # bytes ảnh do model trả
                rel_url = self._save_image_bytes(raw, settings.AI_OUTPUT_DIR, to_format="PNG")
                urls.append(rel_url)

        if not urls:
            raise RuntimeError("Model returned no image parts")

        # Ghép thành absolute URL cho FE
        return [f"{settings.BASE_URL}{u}" for u in urls]
