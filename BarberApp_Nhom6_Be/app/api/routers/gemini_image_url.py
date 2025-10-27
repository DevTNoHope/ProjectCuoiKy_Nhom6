# app/api/routers/gemini_image_url.py
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Depends
from fastapi.responses import JSONResponse
from app.core.config import settings
from app.services.gemini_image_url_service import GeminiImageUrlService

router = APIRouter(prefix="/ai/gemini", tags=["AI"])

def get_service() -> GeminiImageUrlService:
    return GeminiImageUrlService()

@router.post("/edit-image-url")
async def edit_image_and_return_urls(
    image: UploadFile = File(..., description="JPEG/PNG/WebP image"),
    prompt: str = Form("Make the hairstyle cleaner and trendier."),
    svc: GeminiImageUrlService = Depends(get_service),
):
    if image.content_type not in {"image/jpeg", "image/png", "image/webp"}:
        raise HTTPException(status_code=415, detail="Only JPEG/PNG/WebP are supported")

    data = await image.read()
    if len(data) > settings.AI_MAX_IMAGE_MB * 1024 * 1024:
        raise HTTPException(
            status_code=413,
            detail=f"Image too large (> {settings.AI_MAX_IMAGE_MB}MB)",
        )

    try:
        urls = svc.edit_image_and_get_urls(data, image.content_type, prompt)
        return JSONResponse({"urls": urls})
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Gemini error: {e}" )
