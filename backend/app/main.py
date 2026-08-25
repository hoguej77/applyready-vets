from __future__ import annotations

import io
import secrets

from fastapi import Depends, FastAPI, File, HTTPException, Request, UploadFile
from fastapi.responses import JSONResponse, StreamingResponse
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app import __version__
from app.config import is_loopback_host, settings
from app.models import (
    DocumentExtraction, ExportRequest, LinkedInProfileKit, PrivateExportRequest, TailorRequest, TailorResponse,
    URLExtractionRequest,
)
from app.services.documents import apply_approved_edits, build_export_zip, build_private_candidate_zip
from app.services.extractors import extract_document, extract_public_url
from app.services.linkedin import build_linkedin_kit
from app.services.tailoring import TailoringService


security = HTTPBearer(auto_error=False)


def _verify_api_access(token: str | None, server_host: str | None) -> None:
    network_auth_required = (
        settings.environment == "production"
        or not settings.bind_is_loopback
        or not is_loopback_host(server_host)
    )
    if not settings.api_token:
        if network_auth_required:
            raise HTTPException(
                status_code=503,
                detail="Service authentication is not configured",
            )
        return
    if token is None or not secrets.compare_digest(token, settings.api_token):
        raise HTTPException(status_code=401, detail="Invalid API token")


def _request_server_host(request: Request | None) -> str | None:
    if request is None:
        return None
    server = request.scope.get("server")
    if isinstance(server, (tuple, list)) and server:
        return str(server[0])
    return None


def authorize(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
) -> None:
    _verify_api_access(
        credentials.credentials if isinstance(credentials, HTTPAuthorizationCredentials) else None,
        _request_server_host(request),
    )


app = FastAPI(
    title="ApplyReady Vets API",
    version=__version__,
    description="Evidence-backed veteran resume analysis, Truth Lock review, and export service.",
    docs_url="/docs" if settings.environment != "production" else None,
    redoc_url=None,
)
tailoring_service = TailoringService(settings)


@app.middleware("http")
async def enforce_network_authentication(request: Request, call_next):
    authorization = request.headers.get("authorization", "")
    scheme, _separator, supplied = authorization.partition(" ")
    token = supplied if scheme.casefold() == "bearer" and supplied else None
    try:
        _verify_api_access(token, _request_server_host(request))
    except HTTPException as exc:
        return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})
    return await call_next(request)


@app.get("/v1/health")
def health() -> dict:
    ai = tailoring_service.ai_status()
    return {
        "status": "ok",
        "version": __version__,
        "ai_configured": ai["configured"],
        "ai_model": ai["model"],
        "ai_provider": ai["provider"],
        "on_device_ai_available": ai["on_device"],
        "openai_fallback_available": ai["openai_fallback"],
        "truth_lock": True,
        "features": [
            "evidence_ledger", "veteran_translation", "privacy_scan", "job_risk_scan",
            "federal_detection", "gap_questions", "approved_edits_only_export",
            "linkedin_profile_builder", "apple_on_device_ai", "openai_cloud_ai",
            "branch_promotion_packets", "employer_outreach_letters", "college_credit_letters",
            "jofdav_job_board_guidance", "usajobs_resume_checklist", "executive_clearance_notes",
        ],
    }


@app.post("/v1/extract", response_model=DocumentExtraction, dependencies=[Depends(authorize)])
async def extract(file: UploadFile = File(...)) -> DocumentExtraction:
    data = await file.read(settings.max_upload_bytes + 1)
    try:
        result = extract_document(file.filename or "upload", data, settings.max_upload_bytes)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    if len(result.text) > settings.max_text_chars:
        result.text = result.text[: settings.max_text_chars]
        result.warnings.append("Imported text was truncated to the server safety limit.")
    return result


@app.post("/v1/extract-url", response_model=DocumentExtraction, dependencies=[Depends(authorize)])
def extract_url(request: URLExtractionRequest) -> DocumentExtraction:
    try:
        result = extract_public_url(request.url)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    result.text = result.text[: settings.max_text_chars]
    return result


@app.post("/v1/analyze", response_model=TailorResponse, dependencies=[Depends(authorize)])
def analyze(request: TailorRequest) -> TailorResponse:
    return tailoring_service.analyze(request)


@app.post("/v1/export", dependencies=[Depends(authorize)])
def export(request: ExportRequest) -> StreamingResponse:
    try:
        filename, content = build_export_zip(request)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    return StreamingResponse(
        io.BytesIO(content),
        media_type="application/zip",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@app.post("/v1/export/private", dependencies=[Depends(authorize)])
def private_export(request: PrivateExportRequest) -> StreamingResponse:
    try:
        filename, content = build_private_candidate_zip(request)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    return StreamingResponse(
        io.BytesIO(content),
        media_type="application/zip",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@app.post("/v1/linkedin", response_model=LinkedInProfileKit, dependencies=[Depends(authorize)])
def linkedin_profile(request: ExportRequest) -> LinkedInProfileKit:
    try:
        final_text, _trace = apply_approved_edits(request.resume_text, request, strict=True)
        return build_linkedin_kit(request, final_text)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
